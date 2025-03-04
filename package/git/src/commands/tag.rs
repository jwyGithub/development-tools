use anyhow::{Context, Result};
use git2::{ObjectType, PushOptions, Repository};

use crate::models::TagInfo;

pub fn get_tag_info(repo: &Repository) -> Result<(Vec<TagInfo>, Vec<TagInfo>)> {
    let mut tags = Vec::new();

    // 使用 tag_foreach 遍历所有标签
    repo.tag_foreach(|oid, name| {
        if let Ok(name) = std::str::from_utf8(name) {
            if let Ok(obj) = repo.find_object(oid, Some(ObjectType::Any)) {
                // 使用 peel 递归解析标签
                if let Ok(peeled) = obj.peel(ObjectType::Commit) {
                    let message = if obj.kind() == Some(ObjectType::Tag) {
                        // 如果是带注释的标签，获取消息
                        obj.into_tag()
                            .ok()
                            .and_then(|tag| tag.message().map(|s| s.to_string()))
                    } else {
                        None
                    };

                    // 创建标签信息
                    let tag_info = TagInfo::new(
                        name.trim_start_matches("refs/tags/").to_string(),
                        peeled.id().to_string(),
                        message,
                    );

                    tags.push(tag_info);
                }
            }
        }
        true
    })?;

    // 按名称排序
    tags.sort_by(|a, b| a.name.cmp(&b.name));

    // 为了保持接口兼容，返回所有标签作为本地标签
    Ok((tags, Vec::new()))
}

/// 删除标签
pub fn delete_tag(repo: &Repository, tag_name: &str, delete_remote: bool, proxy: Option<String>) -> Result<()> {
    // 检查本地标签是否存在
    let tag_ref = format!("refs/tags/{}", tag_name);
    let mut reference = repo
        .find_reference(&tag_ref)
        .with_context(|| format!("找不到标签 '{}'", tag_name))?;

    // 删除本地标签
    reference
        .delete()
        .with_context(|| format!("删除标签 '{}' 失败", tag_name))?;
    println!("本地标签 '{}' 已删除", tag_name);

    // 如果需要删除远程标签
    if delete_remote {
        // 设置代理
        if let Some(proxy) = proxy {
            std::env::set_var("http.proxy", proxy);
        }
        if let Ok(mut remote) = repo.find_remote("origin") {
            // 构建推送 refspec
            let refspec = format!(":refs/tags/{}", tag_name);
            
            // 创建 PushOptions 实例
            let mut push_options = PushOptions::new();
            
            // 推送删除操作到远程
            remote.push(&[&refspec], Some(&mut push_options))
                .with_context(|| format!("删除远程标签 '{}' 失败", tag_name))?;
        }
    }

    Ok(())
}

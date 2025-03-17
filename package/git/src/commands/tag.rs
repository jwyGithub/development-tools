use anyhow::Result;
use git2::{ObjectType, Repository};

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

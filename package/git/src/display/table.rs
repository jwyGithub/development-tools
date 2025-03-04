use crate::models::{BranchInfo, TagInfo};
use prettytable::{Cell, Row, Table};

pub fn display_branches(local: &[BranchInfo], remote: &[BranchInfo], show_local: bool, show_remote: bool) {
    let mut table = Table::new();
    table.add_row(Row::new(vec![
        Cell::new("类型").style_spec("Fb"),
        Cell::new("分支名").style_spec("Fb"),
        Cell::new("上游分支").style_spec("Fb"),
    ]));

    // 添加本地分支
    if show_local {
        for branch in local {
            table.add_row(Row::new(vec![
                Cell::new("本地"),
                Cell::new(&branch.display_name()),
                Cell::new(&branch.display_upstream()),
            ]));
        }
    }

    // 添加远程分支
    if show_remote {
        for branch in remote {
            table.add_row(Row::new(vec![
                Cell::new("远程"),
                Cell::new(&branch.name),
                Cell::new("-"),
            ]));
        }
    }

    table.printstd();
}

pub fn display_tags(local: &[TagInfo], remote: &[TagInfo], show_local: bool, show_remote: bool) {
    let mut table = Table::new();
    table.add_row(Row::new(vec![
        Cell::new("类型").style_spec("Fb"),
        Cell::new("标签名").style_spec("Fb"),
        Cell::new("提交ID").style_spec("Fb"),
        Cell::new("消息").style_spec("Fb"),
    ]));

    if show_local {
        for tag in local {
            table.add_row(Row::new(vec![
                Cell::new("本地"),
                Cell::new(&tag.display_name(true)),
                Cell::new(&tag.display_commit()),
                Cell::new(&tag.display_message()),
            ]));
        }
    }

    if show_remote {
        for tag in remote {
            table.add_row(Row::new(vec![
                Cell::new("远程"),
                Cell::new(&tag.display_name(false)),
                Cell::new(&tag.display_commit()),
                Cell::new(&tag.display_message()),
            ]));
        }
    }

    table.printstd();
} 

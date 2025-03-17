mod list;
mod table;

pub use list::{display_branches as display_branches_list, display_tags as display_tags_list};
pub use table::{display_branches as display_branches_table, display_tags as display_tags_table};

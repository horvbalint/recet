-- Run once after a 3.x datastore was first opened by SurrealDB 4.0, statement by statement
-- (not inside a transaction). Indexes built by 3.x keep working but:
-- - full-text: BM25 stats still count records that were updated and later deleted
-- - date_unique: datetimes are stored as text, so ranges/ORDER BY on `date` can be out of order
-- - every B-tree: planned as possibly holding arrays, so ORDER BY/count() can't use it

REBUILD INDEX hungarian_search_name ON recipe;
REBUILD INDEX english_search_name ON recipe;
REBUILD INDEX hungarian_search_name ON meal;
REBUILD INDEX english_search_name ON meal;
REBUILD INDEX hungarian_search_name ON cuisine;
REBUILD INDEX english_search_name ON cuisine;
REBUILD INDEX hungarian_search_name ON recipe_tag;
REBUILD INDEX english_search_name ON recipe_tag;
REBUILD INDEX hungarian_search_name ON ingredient;
REBUILD INDEX english_search_name ON ingredient;
REBUILD INDEX hungarian_search_name ON unit;
REBUILD INDEX english_search_name ON unit;

REBUILD INDEX date_unique ON meal_plan;
REBUILD INDEX email_unique ON user;
REBUILD INDEX username_unique ON user;
REBUILD INDEX member_unique ON member;
REBUILD INDEX token_unique ON invitation;

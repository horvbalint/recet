BEGIN TRANSACTION;

// TABLE: user
DEFINE TABLE OVERWRITE user SCHEMAFULL PERMISSIONS
	FOR select WHERE deleted = false
	FOR update WHERE id = $auth.id
	FOR create, delete NONE;

DEFINE FIELD OVERWRITE email ON user TYPE string ASSERT string::is::email($value) PERMISSIONS FOR select WHERE id = $auth.id;
DEFINE FIELD OVERWRITE username ON user TYPE string;
DEFINE FIELD OVERWRITE password ON user TYPE string PERMISSIONS NONE;
DEFINE FIELD OVERWRITE deleted ON user TYPE bool DEFAULT false PERMISSIONS NONE;
DEFINE FIELD OVERWRITE created_at ON user TYPE datetime DEFAULT time::now();
DEFINE FIELD OVERWRITE updated_at ON user TYPE datetime VALUE time::now() PERMISSIONS NONE;

DEFINE INDEX OVERWRITE email_unique ON user FIELDS email UNIQUE;
DEFINE INDEX OVERWRITE username_unique ON user FIELDS username UNIQUE;

// Define user authentication
DEFINE ACCESS OVERWRITE user ON DATABASE TYPE RECORD
	SIGNUP ( CREATE user SET email = $email, username = $username, password = crypto::argon2::generate($password) )
	SIGNIN ( SELECT * FROM ONLY user WHERE email = $email && crypto::argon2::compare(password, $password) && deleted = false )
	DURATION FOR TOKEN 15m, FOR SESSION 12h
;

// TABLE: recipe
DEFINE TABLE OVERWRITE recipe SCHEMAFULL PERMISSIONS FULL;
DEFINE FIELD OVERWRITE name ON recipe TYPE string;
DEFINE FIELD OVERWRITE ingredients ON recipe TYPE array<object> DEFAULT [];
DEFINE FIELD OVERWRITE ingredients.*.ingredient ON recipe TYPE record<ingredient>;
DEFINE FIELD OVERWRITE ingredients.*.amount ON recipe TYPE option<number>;
DEFINE FIELD OVERWRITE ingredients.*.unit ON recipe TYPE option<record<unit>>;
DEFINE FIELD OVERWRITE ingredients.*.description ON recipe TYPE option<string>;
DEFINE FIELD OVERWRITE steps ON recipe TYPE array<string> DEFAULT [];
DEFINE FIELD OVERWRITE author ON recipe TYPE record<user>;
DEFINE FIELD OVERWRITE tags ON recipe TYPE array<record<recipe_tag>> DEFAULT [];
DEFINE FIELD OVERWRITE cuisine ON recipe TYPE option<record<cuisine>>;
DEFINE FIELD OVERWRITE meal ON recipe TYPE array<record<meal>> DEFAULT [];
DEFINE FIELD OVERWRITE created_at ON recipe TYPE datetime DEFAULT time::now();
DEFINE FIELD OVERWRITE updated_at ON recipe TYPE datetime VALUE time::now();

// TABLE: meal
DEFINE TABLE OVERWRITE meal SCHEMAFULL PERMISSIONS FULL;
DEFINE FIELD OVERWRITE name ON meal TYPE string;
DEFINE FIELD OVERWRITE color ON meal TYPE string;

// TABLE: cuisine
DEFINE TABLE OVERWRITE cuisine SCHEMAFULL PERMISSIONS FULL;
DEFINE FIELD OVERWRITE name ON cuisine TYPE string;
DEFINE FIELD OVERWRITE color ON cuisine TYPE string;
DEFINE FIELD OVERWRITE flag ON cuisine TYPE option<string>;

// TABLE: recipe_tag
DEFINE TABLE OVERWRITE recipe_tag SCHEMAFULL PERMISSIONS FULL;
DEFINE FIELD OVERWRITE name ON recipe_tag TYPE string;  
DEFINE FIELD OVERWRITE color ON recipe_tag TYPE string;
DEFINE FIELD OVERWRITE icon ON recipe_tag TYPE string;

// TABLE: ingredient
DEFINE TABLE OVERWRITE ingredient SCHEMAFULL PERMISSIONS FULL;
DEFINE FIELD OVERWRITE name ON ingredient TYPE string;
DEFINE FIELD OVERWRITE category ON ingredient TYPE option<record<ingredient_category>>;
DEFINE FIELD OVERWRITE skip_from_shopping_list ON ingredient TYPE bool DEFAULT false;

// TABLE: category
DEFINE TABLE OVERWRITE ingredient_category SCHEMAFULL PERMISSIONS FULL;
DEFINE FIELD OVERWRITE name ON ingredient_category TYPE string;

// TABLE: unit
DEFINE TABLE OVERWRITE unit SCHEMAFULL PERMISSIONS FULL;
DEFINE FIELD OVERWRITE name ON unit TYPE string;

// TABLE: household
DEFINE TABLE OVERWRITE household SCHEMAFULL PERMISSIONS
	FOR select WHERE $auth.id IN users;

DEFINE FIELD OVERWRITE name ON household TYPE string;
DEFINE FIELD OVERWRITE users ON household TYPE array<record<user>>;
DEFINE FIELD OVERWRITE created_at ON household TYPE datetime DEFAULT time::now();
DEFINE FIELD OVERWRITE updated_at ON household TYPE datetime VALUE time::now();

// TABLE: shopping_list
DEFINE TABLE OVERWRITE shopping_list SCHEMAFULL PERMISSIONS FULL;
DEFINE FIELD OVERWRITE household ON shopping_list TYPE record<household>;
DEFINE FIELD OVERWRITE name ON shopping_list TYPE string;
DEFINE FIELD OVERWRITE items ON shopping_list TYPE array<object> DEFAULT [];
DEFINE FIELD OVERWRITE items.*.ingredient ON shopping_list TYPE record<ingredient>;
DEFINE FIELD OVERWRITE items.*.amount ON shopping_list TYPE option<number>;
DEFINE FIELD OVERWRITE items.*.unit ON shopping_list TYPE option<record<unit>>;
DEFINE FIELD OVERWRITE items.*.checked ON shopping_list TYPE bool DEFAULT false;
DEFINE FIELD OVERWRITE items.*.flagged ON shopping_list TYPE bool DEFAULT false;
DEFINE FIELD OVERWRITE updated_at ON shopping_list TYPE datetime VALUE time::now();

// TABLE: weekly_plan
DEFINE TABLE OVERWRITE weekly_plan SCHEMAFULL PERMISSIONS FULL;
DEFINE FIELD OVERWRITE name ON weekly_plan TYPE string;

DEFINE FIELD OVERWRITE monday ON weekly_plan TYPE object;
DEFINE FIELD OVERWRITE monday.breakfast ON weekly_plan TYPE object;
DEFINE FIELD OVERWRITE monday.breakfast.recipes ON weekly_plan TYPE array<record<recipe>>;
DEFINE FIELD OVERWRITE monday.breakfast.rules ON weekly_plan TYPE array<record<recipe_tag>>;
DEFINE FIELD OVERWRITE monday.lunch ON weekly_plan TYPE object;
DEFINE FIELD OVERWRITE monday.lunch.recipes ON weekly_plan TYPE array<record<recipe>>;
DEFINE FIELD OVERWRITE monday.lunch.rules ON weekly_plan TYPE array<record<recipe_tag>>;
DEFINE FIELD OVERWRITE monday.dinner ON weekly_plan TYPE object;
DEFINE FIELD OVERWRITE monday.dinner.recipes ON weekly_plan TYPE array<record<recipe>>;
DEFINE FIELD OVERWRITE monday.dinner.rules ON weekly_plan TYPE array<record<recipe_tag>>;
DEFINE FIELD OVERWRITE monday.other ON weekly_plan TYPE object;
DEFINE FIELD OVERWRITE monday.other.recipes ON weekly_plan TYPE array<record<recipe>>;
DEFINE FIELD OVERWRITE monday.other.rules ON weekly_plan TYPE array<record<recipe_tag>>;

DEFINE FIELD OVERWRITE tuesday ON weekly_plan TYPE object;
DEFINE FIELD OVERWRITE tuesday.breakfast ON weekly_plan TYPE object;
DEFINE FIELD OVERWRITE tuesday.breakfast.recipes ON weekly_plan TYPE array<record<recipe>>;
DEFINE FIELD OVERWRITE tuesday.breakfast.rules ON weekly_plan TYPE array<record<recipe_tag>>;
DEFINE FIELD OVERWRITE tuesday.lunch ON weekly_plan TYPE object;
DEFINE FIELD OVERWRITE tuesday.lunch.recipes ON weekly_plan TYPE array<record<recipe>>;
DEFINE FIELD OVERWRITE tuesday.lunch.rules ON weekly_plan TYPE array<record<recipe_tag>>;
DEFINE FIELD OVERWRITE tuesday.dinner ON weekly_plan TYPE object;
DEFINE FIELD OVERWRITE tuesday.dinner.recipes ON weekly_plan TYPE array<record<recipe>>;
DEFINE FIELD OVERWRITE tuesday.dinner.rules ON weekly_plan TYPE array<record<recipe_tag>>;
DEFINE FIELD OVERWRITE tuesday.other ON weekly_plan TYPE object;
DEFINE FIELD OVERWRITE tuesday.other.recipes ON weekly_plan TYPE array<record<recipe>>;
DEFINE FIELD OVERWRITE tuesday.other.rules ON weekly_plan TYPE array<record<recipe_tag>>;

DEFINE FIELD OVERWRITE wednesday ON weekly_plan TYPE object;
DEFINE FIELD OVERWRITE wednesday.breakfast ON weekly_plan TYPE object;
DEFINE FIELD OVERWRITE wednesday.breakfast.recipes ON weekly_plan TYPE array<record<recipe>>;
DEFINE FIELD OVERWRITE wednesday.breakfast.rules ON weekly_plan TYPE array<record<recipe_tag>>;
DEFINE FIELD OVERWRITE wednesday.lunch ON weekly_plan TYPE object;
DEFINE FIELD OVERWRITE wednesday.lunch.recipes ON weekly_plan TYPE array<record<recipe>>;
DEFINE FIELD OVERWRITE wednesday.lunch.rules ON weekly_plan TYPE array<record<recipe_tag>>;
DEFINE FIELD OVERWRITE wednesday.dinner ON weekly_plan TYPE object;
DEFINE FIELD OVERWRITE wednesday.dinner.recipes ON weekly_plan TYPE array<record<recipe>>;
DEFINE FIELD OVERWRITE wednesday.dinner.rules ON weekly_plan TYPE array<record<recipe_tag>>;
DEFINE FIELD OVERWRITE wednesday.other ON weekly_plan TYPE object;
DEFINE FIELD OVERWRITE wednesday.other.recipes ON weekly_plan TYPE array<record<recipe>>;
DEFINE FIELD OVERWRITE wednesday.other.rules ON weekly_plan TYPE array<record<recipe_tag>>;

DEFINE FIELD OVERWRITE thursday ON weekly_plan TYPE object;
DEFINE FIELD OVERWRITE thursday.breakfast ON weekly_plan TYPE object;
DEFINE FIELD OVERWRITE thursday.breakfast.recipes ON weekly_plan TYPE array<record<recipe>>;
DEFINE FIELD OVERWRITE thursday.breakfast.rules ON weekly_plan TYPE array<record<recipe_tag>>;
DEFINE FIELD OVERWRITE thursday.lunch ON weekly_plan TYPE object;
DEFINE FIELD OVERWRITE thursday.lunch.recipes ON weekly_plan TYPE array<record<recipe>>;
DEFINE FIELD OVERWRITE thursday.lunch.rules ON weekly_plan TYPE array<record<recipe_tag>>;
DEFINE FIELD OVERWRITE thursday.dinner ON weekly_plan TYPE object;
DEFINE FIELD OVERWRITE thursday.dinner.recipes ON weekly_plan TYPE array<record<recipe>>;
DEFINE FIELD OVERWRITE thursday.dinner.rules ON weekly_plan TYPE array<record<recipe_tag>>;
DEFINE FIELD OVERWRITE thursday.other ON weekly_plan TYPE object;
DEFINE FIELD OVERWRITE thursday.other.recipes ON weekly_plan TYPE array<record<recipe>>;
DEFINE FIELD OVERWRITE thursday.other.rules ON weekly_plan TYPE array<record<recipe_tag>>;

DEFINE FIELD OVERWRITE friday ON weekly_plan TYPE object;
DEFINE FIELD OVERWRITE friday.breakfast ON weekly_plan TYPE object;
DEFINE FIELD OVERWRITE friday.breakfast.recipes ON weekly_plan TYPE array<record<recipe>>;
DEFINE FIELD OVERWRITE friday.breakfast.rules ON weekly_plan TYPE array<record<recipe_tag>>;
DEFINE FIELD OVERWRITE friday.lunch ON weekly_plan TYPE object;
DEFINE FIELD OVERWRITE friday.lunch.recipes ON weekly_plan TYPE array<record<recipe>>;
DEFINE FIELD OVERWRITE friday.lunch.rules ON weekly_plan TYPE array<record<recipe_tag>>;
DEFINE FIELD OVERWRITE friday.dinner ON weekly_plan TYPE object;
DEFINE FIELD OVERWRITE friday.dinner.recipes ON weekly_plan TYPE array<record<recipe>>;
DEFINE FIELD OVERWRITE friday.dinner.rules ON weekly_plan TYPE array<record<recipe_tag>>;
DEFINE FIELD OVERWRITE friday.other ON weekly_plan TYPE object;
DEFINE FIELD OVERWRITE friday.other.recipes ON weekly_plan TYPE array<record<recipe>>;
DEFINE FIELD OVERWRITE friday.other.rules ON weekly_plan TYPE array<record<recipe_tag>>;

DEFINE FIELD OVERWRITE saturday ON weekly_plan TYPE object;
DEFINE FIELD OVERWRITE saturday.breakfast ON weekly_plan TYPE object;
DEFINE FIELD OVERWRITE saturday.breakfast.recipes ON weekly_plan TYPE array<record<recipe>>;
DEFINE FIELD OVERWRITE saturday.breakfast.rules ON weekly_plan TYPE array<record<recipe_tag>>;
DEFINE FIELD OVERWRITE saturday.lunch ON weekly_plan TYPE object;
DEFINE FIELD OVERWRITE saturday.lunch.recipes ON weekly_plan TYPE array<record<recipe>>;
DEFINE FIELD OVERWRITE saturday.lunch.rules ON weekly_plan TYPE array<record<recipe_tag>>;
DEFINE FIELD OVERWRITE saturday.dinner ON weekly_plan TYPE object;
DEFINE FIELD OVERWRITE saturday.dinner.recipes ON weekly_plan TYPE array<record<recipe>>;
DEFINE FIELD OVERWRITE saturday.dinner.rules ON weekly_plan TYPE array<record<recipe_tag>>;
DEFINE FIELD OVERWRITE saturday.other ON weekly_plan TYPE object;
DEFINE FIELD OVERWRITE saturday.other.recipes ON weekly_plan TYPE array<record<recipe>>;
DEFINE FIELD OVERWRITE saturday.other.rules ON weekly_plan TYPE array<record<recipe_tag>>;

DEFINE FIELD OVERWRITE sunday ON weekly_plan TYPE object;
DEFINE FIELD OVERWRITE sunday.breakfast ON weekly_plan TYPE object;
DEFINE FIELD OVERWRITE sunday.breakfast.recipes ON weekly_plan TYPE array<record<recipe>>;
DEFINE FIELD OVERWRITE sunday.breakfast.rules ON weekly_plan TYPE array<record<recipe_tag>>;
DEFINE FIELD OVERWRITE sunday.lunch ON weekly_plan TYPE object;
DEFINE FIELD OVERWRITE sunday.lunch.recipes ON weekly_plan TYPE array<record<recipe>>;
DEFINE FIELD OVERWRITE sunday.lunch.rules ON weekly_plan TYPE array<record<recipe_tag>>;
DEFINE FIELD OVERWRITE sunday.dinner ON weekly_plan TYPE object;
DEFINE FIELD OVERWRITE sunday.dinner.recipes ON weekly_plan TYPE array<record<recipe>>;
DEFINE FIELD OVERWRITE sunday.dinner.rules ON weekly_plan TYPE array<record<recipe_tag>>;
DEFINE FIELD OVERWRITE sunday.other ON weekly_plan TYPE object;
DEFINE FIELD OVERWRITE sunday.other.recipes ON weekly_plan TYPE array<record<recipe>>;
DEFINE FIELD OVERWRITE sunday.other.rules ON weekly_plan TYPE array<record<recipe_tag>>;

COMMIT;
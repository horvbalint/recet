// TABLE: user
DEFINE TABLE user SCHEMAFULL;
DEFINE FIELD email ON user TYPE string ASSERT string::is::email($value);
DEFINE FIELD username ON user TYPE string;
DEFINE FIELD password ON user TYPE string VALUE crypto::bcrypt::generate($value);
DEFINE FIELD deleted ON user TYPE bool DEFAULT false;

DEFINE INDEX email_unique ON user FIELDS email UNIQUE;

// TABLE: recipe
DEFINE TABLE recipe SCHEMAFULL;
DEFINE FIELD name ON recipe TYPE string;
DEFINE FIELD ingredients ON recipe TYPE array<object> DEFAULT [];
DEFINE FIELD ingredients.*.ingredient ON recipe TYPE record<ingredient>;
DEFINE FIELD ingredients.*.amount ON recipe TYPE option<number>;
DEFINE FIELD ingredients.*.unit ON recipe TYPE option<record<unit>>;
DEFINE FIELD ingredients.*.description ON recipe TYPE option<string>;
DEFINE FIELD steps ON recipe TYPE array<string> DEFAULT [];
DEFINE FIELD author ON recipe TYPE record<user>;
DEFINE FIELD tags ON recipe TYPE array<record<recipe_tag>> DEFAULT [];
DEFINE FIELD cuisine ON recipe TYPE option<record<cuisine>>;
DEFINE FIELD meal ON recipe TYPE array<record<meal>> DEFAULT [];

// TABLE: meal
DEFINE TABLE meal SCHEMAFULL;
DEFINE FIELD name ON meal TYPE string;
DEFINE FIELD color ON cuisine TYPE string;

// TABLE: cuisine
DEFINE TABLE cuisine SCHEMAFULL;
DEFINE FIELD name ON cuisine TYPE string;
DEFINE FIELD color ON cuisine TYPE string;
DEFINE FIELD flag ON cuisine TYPE option<string>;

// TABLE: recipe_tag
DEFINE TABLE recipe_tag SCHEMAFULL;
DEFINE FIELD name ON recipe_tag TYPE string;  
DEFINE FIELD color ON recipe_tag TYPE string;
DEFINE FIELD icon ON recipe_tag TYPE string;

// TABLE: ingredient
DEFINE TABLE ingredient SCHEMAFULL;
DEFINE FIELD name ON ingredient TYPE string;
DEFINE FIELD category ON ingredient TYPE option<record<ingredient_category>>;

// TABLE: category
DEFINE TABLE ingredient_category SCHEMAFULL;
DEFINE FIELD name ON ingredient_category TYPE string;

// TABLE: unit
DEFINE TABLE unit SCHEMAFULL;
DEFINE FIELD name ON unit TYPE string;

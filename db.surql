// TABLE: user
DEFINE TABLE user SCHEMAFULL;
DEFINE FIELD email ON user TYPE string ASSERT string::is::email($value);
DEFINE FIELD username ON user TYPE string;
DEFINE FIELD password ON user TYPE string VALUE crypto::bcrypt::generate($value);
DEFINE FIELD deleted ON user TYPE bool DEFAULT false;
DEFINE FIELD created_at ON user TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON user TYPE datetime VALUE time::now();

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
DEFINE FIELD created_at ON recipe TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON recipe TYPE datetime VALUE time::now();

// TABLE: meal
DEFINE TABLE meal SCHEMAFULL;
DEFINE FIELD name ON meal TYPE string;
DEFINE FIELD color ON meal TYPE string;

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
DEFINE FIELD skip_from_shopping_list ON ingredient TYPE bool DEFAULT false;

// TABLE: category
DEFINE TABLE ingredient_category SCHEMAFULL;
DEFINE FIELD name ON ingredient_category TYPE string;

// TABLE: unit
DEFINE TABLE unit SCHEMAFULL;
DEFINE FIELD name ON unit TYPE string;

// TABLE: household
DEFINE TABLE household SCHEMAFULL;
DEFINE FIELD name ON household TYPE string;
DEFINE FIELD users ON household TYPE array<record<user>>;
DEFINE FIELD created_at ON household TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON household TYPE datetime VALUE time::now();

// TABLE: shopping_list
DEFINE TABLE shopping_list SCHEMAFULL;
DEFINE FIELD household ON shopping_list TYPE record<household>;
DEFINE FIELD name ON shopping_list TYPE string;
DEFINE FIELD items ON shopping_list TYPE array<object> DEFAULT [];
DEFINE FIELD items.*.ingredient ON shopping_list TYPE record<ingredient>;
DEFINE FIELD items.*.amount ON shopping_list TYPE option<number>;
DEFINE FIELD items.*.unit ON shopping_list TYPE option<record<unit>>;
DEFINE FIELD items.*.checked ON shopping_list TYPE bool DEFAULT false;
DEFINE FIELD items.*.flagged ON shopping_list TYPE bool DEFAULT false;
DEFINE FIELD updated_at ON shopping_list TYPE datetime VALUE time::now();

// TABLE: weekly_plan
DEFINE TABLE weekly_plan SCHEMAFULL;
DEFINE FIELD name ON weekly_plan TYPE string;
DEFINE FIELD monday ON weekly_plan TYPE object;
DEFINE FIELD monday.breakfast ON weekly_plan TYPE object;
DEFINE FIELD monday.breakfast.recipes ON weekly_plan TYPE array<recipe>;
DEFINE FIELD monday.breakfast.rules ON weekly_plan TYPE array<recipe_tag>;
DEFINE FIELD monday.lunch ON weekly_plan TYPE object;
DEFINE FIELD monday.lunch.recipes ON weekly_plan TYPE array<recipe>;
DEFINE FIELD monday.lunch.rules ON weekly_plan TYPE array<recipe_tag>;
DEFINE FIELD monday.dinner ON weekly_plan TYPE object;
DEFINE FIELD monday.dinner.recipes ON weekly_plan TYPE array<recipe>;
DEFINE FIELD monday.dinner.rules ON weekly_plan TYPE array<recipe_tag>;
DEFINE FIELD monday.other ON weekly_plan TYPE object;
DEFINE FIELD monday.other.recipes ON weekly_plan TYPE array<recipe>;
DEFINE FIELD monday.other.rules ON weekly_plan TYPE array<recipe_tag>;
DEFINE FIELD tuesday ON weekly_plan TYPE object;
DEFINE FIELD tuesday.breakfast ON weekly_plan TYPE object;
DEFINE FIELD tuesday.breakfast.recipes ON weekly_plan TYPE array<recipe>;
DEFINE FIELD tuesday.breakfast.rules ON weekly_plan TYPE array<recipe_tag>;
DEFINE FIELD tuesday.lunch ON weekly_plan TYPE object;
DEFINE FIELD tuesday.lunch.recipes ON weekly_plan TYPE array<recipe>;
DEFINE FIELD tuesday.lunch.rules ON weekly_plan TYPE array<recipe_tag>;
DEFINE FIELD tuesday.dinner ON weekly_plan TYPE object;
DEFINE FIELD tuesday.dinner.recipes ON weekly_plan TYPE array<recipe>;
DEFINE FIELD tuesday.dinner.rules ON weekly_plan TYPE array<recipe_tag>;
DEFINE FIELD tuesday.other ON weekly_plan TYPE object;
DEFINE FIELD tuesday.other.recipes ON weekly_plan TYPE array<recipe>;
DEFINE FIELD tuesday.other.rules ON weekly_plan TYPE array<recipe_tag>;
DEFINE FIELD wednesday ON weekly_plan TYPE object;
DEFINE FIELD wednesday.breakfast ON weekly_plan TYPE object;
DEFINE FIELD wednesday.breakfast.recipes ON weekly_plan TYPE array<recipe>;
DEFINE FIELD wednesday.breakfast.rules ON weekly_plan TYPE array<recipe_tag>;
DEFINE FIELD wednesday.lunch ON weekly_plan TYPE object;
DEFINE FIELD wednesday.lunch.recipes ON weekly_plan TYPE array<recipe>;
DEFINE FIELD wednesday.lunch.rules ON weekly_plan TYPE array<recipe_tag>;
DEFINE FIELD wednesday.dinner ON weekly_plan TYPE object;
DEFINE FIELD wednesday.dinner.recipes ON weekly_plan TYPE array<recipe>;
DEFINE FIELD wednesday.dinner.rules ON weekly_plan TYPE array<recipe_tag>;
DEFINE FIELD wednesday.other ON weekly_plan TYPE object;
DEFINE FIELD wednesday.other.recipes ON weekly_plan TYPE array<recipe>;
DEFINE FIELD wednesday.other.rules ON weekly_plan TYPE array<recipe_tag>;
DEFINE FIELD thursday ON weekly_plan TYPE object;
DEFINE FIELD thursday.breakfast ON weekly_plan TYPE object;
DEFINE FIELD thursday.breakfast.recipes ON weekly_plan TYPE array<recipe>;
DEFINE FIELD thursday.breakfast.rules ON weekly_plan TYPE array<recipe_tag>;
DEFINE FIELD thursday.lunch ON weekly_plan TYPE object;
DEFINE FIELD thursday.lunch.recipes ON weekly_plan TYPE array<recipe>;
DEFINE FIELD thursday.lunch.rules ON weekly_plan TYPE array<recipe_tag>;
DEFINE FIELD thursday.dinner ON weekly_plan TYPE object;
DEFINE FIELD thursday.dinner.recipes ON weekly_plan TYPE array<recipe>;
DEFINE FIELD thursday.dinner.rules ON weekly_plan TYPE array<recipe_tag>;
DEFINE FIELD thursday.other ON weekly_plan TYPE object;
DEFINE FIELD thursday.other.recipes ON weekly_plan TYPE array<recipe>;
DEFINE FIELD thursday.other.rules ON weekly_plan TYPE array<recipe_tag>;
DEFINE FIELD friday ON weekly_plan TYPE object;
DEFINE FIELD friday.breakfast ON weekly_plan TYPE object;
DEFINE FIELD friday.breakfast.recipes ON weekly_plan TYPE array<recipe>;
DEFINE FIELD friday.breakfast.rules ON weekly_plan TYPE array<recipe_tag>;
DEFINE FIELD friday.lunch ON weekly_plan TYPE object;
DEFINE FIELD friday.lunch.recipes ON weekly_plan TYPE array<recipe>;
DEFINE FIELD friday.lunch.rules ON weekly_plan TYPE array<recipe_tag>;
DEFINE FIELD friday.dinner ON weekly_plan TYPE object;
DEFINE FIELD friday.dinner.recipes ON weekly_plan TYPE array<recipe>;
DEFINE FIELD friday.dinner.rules ON weekly_plan TYPE array<recipe_tag>;
DEFINE FIELD friday.other ON weekly_plan TYPE object;
DEFINE FIELD friday.other.recipes ON weekly_plan TYPE array<recipe>;
DEFINE FIELD friday.other.rules ON weekly_plan TYPE array<recipe_tag>;
DEFINE FIELD saturday ON weekly_plan TYPE object;
DEFINE FIELD saturday.breakfast ON weekly_plan TYPE object;
DEFINE FIELD saturday.breakfast.recipes ON weekly_plan TYPE array<recipe>;
DEFINE FIELD saturday.breakfast.rules ON weekly_plan TYPE array<recipe_tag>;
DEFINE FIELD saturday.lunch ON weekly_plan TYPE object;
DEFINE FIELD saturday.lunch.recipes ON weekly_plan TYPE array<recipe>;
DEFINE FIELD saturday.lunch.rules ON weekly_plan TYPE array<recipe_tag>;
DEFINE FIELD saturday.dinner ON weekly_plan TYPE object;
DEFINE FIELD saturday.dinner.recipes ON weekly_plan TYPE array<recipe>;
DEFINE FIELD saturday.dinner.rules ON weekly_plan TYPE array<recipe_tag>;
DEFINE FIELD saturday.other ON weekly_plan TYPE object;
DEFINE FIELD saturday.other.recipes ON weekly_plan TYPE array<recipe>;
DEFINE FIELD saturday.other.rules ON weekly_plan TYPE array<recipe_tag>;
DEFINE FIELD sunday ON weekly_plan TYPE object;
DEFINE FIELD sunday.breakfast ON weekly_plan TYPE object;
DEFINE FIELD sunday.breakfast.recipes ON weekly_plan TYPE array<recipe>;
DEFINE FIELD sunday.breakfast.rules ON weekly_plan TYPE array<recipe_tag>;
DEFINE FIELD sunday.lunch ON weekly_plan TYPE object;
DEFINE FIELD sunday.lunch.recipes ON weekly_plan TYPE array<recipe>;
DEFINE FIELD sunday.lunch.rules ON weekly_plan TYPE array<recipe_tag>;
DEFINE FIELD sunday.dinner ON weekly_plan TYPE object;
DEFINE FIELD sunday.dinner.recipes ON weekly_plan TYPE array<recipe>;
DEFINE FIELD sunday.dinner.rules ON weekly_plan TYPE array<recipe_tag>;
DEFINE FIELD sunday.other ON weekly_plan TYPE object;
DEFINE FIELD sunday.other.recipes ON weekly_plan TYPE array<recipe>;
DEFINE FIELD sunday.other.rules ON weekly_plan TYPE array<recipe_tag>;

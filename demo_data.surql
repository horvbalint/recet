-- ------------------------------
-- OPTION
-- ------------------------------

OPTION IMPORT;

-- ------------------------------
-- TABLE: cuisine
-- ------------------------------

DEFINE TABLE cuisine TYPE NORMAL SCHEMAFULL PERMISSIONS NONE;

DEFINE FIELD color ON cuisine TYPE string PERMISSIONS FULL;
DEFINE FIELD flag ON cuisine TYPE option<string> PERMISSIONS FULL;
DEFINE FIELD name ON cuisine TYPE string PERMISSIONS FULL;



-- ------------------------------
-- TABLE DATA: cuisine
-- ------------------------------

INSERT [ { color: '#25ad3b', flag: '🇮🇹', id: cuisine:ahycm1yruhlvu3mb7a8l, name: 'testttt' }, { color: '#ff6b6b', flag: '🇮🇹', id: cuisine:ezuiprf3bxbf058e55pw, name: 'Italian' }, { color: '#a8e6cf', flag: '🇺🇸', id: cuisine:kd4ewtmdksdskequl9va, name: 'American' }, { color: '#ffe66d', flag: '🌏', id: cuisine:op12176ds4fyqm8lbcgv, name: 'Asian' }, { color: '#dda0dd', flag: '🇫🇷', id: cuisine:sebuiaxtu0nr2xkivpkj, name: 'French' }, { color: '#4ecdc4', flag: '🇲🇽', id: cuisine:wr7mbxix6ddo09n8fe1j, name: 'Mexican' } ];

-- ------------------------------
-- TABLE: household
-- ------------------------------

DEFINE TABLE household TYPE NORMAL SCHEMAFULL PERMISSIONS NONE;

DEFINE FIELD created_at ON household TYPE datetime DEFAULT time::now() PERMISSIONS FULL;
DEFINE FIELD name ON household TYPE string PERMISSIONS FULL;
DEFINE FIELD updated_at ON household TYPE datetime VALUE time::now() PERMISSIONS FULL;
DEFINE FIELD users ON household TYPE array<record<user>> PERMISSIONS FULL;
DEFINE FIELD users[*] ON household TYPE record<user> PERMISSIONS FULL;



-- ------------------------------
-- TABLE DATA: household
-- ------------------------------


-- ------------------------------
-- TABLE: ingredient
-- ------------------------------

DEFINE TABLE ingredient TYPE NORMAL SCHEMAFULL PERMISSIONS NONE;

DEFINE FIELD category ON ingredient TYPE option<record<ingredient_category>> PERMISSIONS FULL;
DEFINE FIELD name ON ingredient TYPE string PERMISSIONS FULL;
DEFINE FIELD skip_from_shopping_list ON ingredient TYPE bool DEFAULT false PERMISSIONS FULL;



-- ------------------------------
-- TABLE DATA: ingredient
-- ------------------------------

INSERT [ { category: ingredient_category:708ruu9h2tchj963g788, id: ingredient:2s29078zl3tzoa5glip0, name: 'Tomato', skip_from_shopping_list: false }, { category: ingredient_category:6l193z7n8xie5wzcftk5, id: ingredient:3ht19sif4gkj9m799dhi, name: 'Olive Oil', skip_from_shopping_list: false }, { category: ingredient_category:708ruu9h2tchj963g788, id: ingredient:6ir6u5znxrum2tdsc9x7, name: 'Bell Pepper', skip_from_shopping_list: false }, { category: ingredient_category:37ppvt6i80laypo9esil, id: ingredient:89zb8gyyjvttp42b9qgx, name: 'Parmesan Cheese', skip_from_shopping_list: false }, { category: ingredient_category:dbd8gsxkymvrar9m51zh, id: ingredient:c3zuikeoh4odb0rkpwzo, name: 'Salt', skip_from_shopping_list: true }, { category: ingredient_category:4e6bnpqlg04x60v83p6k, id: ingredient:d6oho5h8pr5qqpgq4jui, name: 'Ground Beef', skip_from_shopping_list: false }, { category: ingredient_category:dbd8gsxkymvrar9m51zh, id: ingredient:f9ep4ir98c38ou65bwon, name: 'Basil', skip_from_shopping_list: false }, { category: ingredient_category:37ppvt6i80laypo9esil, id: ingredient:ig0527g34zxypjz39q9l, name: 'Mozzarella Cheese', skip_from_shopping_list: false }, { category: ingredient_category:4e6bnpqlg04x60v83p6k, id: ingredient:ioiw9ocyxrg14zlkb529, name: 'Tofu', skip_from_shopping_list: false }, { category: ingredient_category:708ruu9h2tchj963g788, id: ingredient:jomn81vjr1uuti6yq322, name: 'Onion', skip_from_shopping_list: false }, { category: ingredient_category:5m0dljna7o6inoff5u93, id: ingredient:o084zdfk58avr77mf8hj, name: 'Rice', skip_from_shopping_list: false }, { category: ingredient_category:708ruu9h2tchj963g788, id: ingredient:tanhs35fguiqzehurdxe, name: 'Garlic', skip_from_shopping_list: false }, { category: ingredient_category:4e6bnpqlg04x60v83p6k, id: ingredient:x8spri9jy77u6l8f9pnd, name: 'Chicken Breast', skip_from_shopping_list: false }, { category: ingredient_category:dbd8gsxkymvrar9m51zh, id: ingredient:ydygrnlh130uyqh08vfq, name: 'Black Pepper', skip_from_shopping_list: true }, { category: ingredient_category:5m0dljna7o6inoff5u93, id: ingredient:ykezqetthtd3zmnd132h, name: 'Pasta', skip_from_shopping_list: false } ];

-- ------------------------------
-- TABLE: ingredient_category
-- ------------------------------

DEFINE TABLE ingredient_category TYPE NORMAL SCHEMAFULL PERMISSIONS NONE;

DEFINE FIELD name ON ingredient_category TYPE string PERMISSIONS FULL;



-- ------------------------------
-- TABLE DATA: ingredient_category
-- ------------------------------

INSERT [ { id: ingredient_category:37ppvt6i80laypo9esil, name: 'Dairy' }, { id: ingredient_category:4e6bnpqlg04x60v83p6k, name: 'Proteins' }, { id: ingredient_category:5m0dljna7o6inoff5u93, name: 'Grains' }, { id: ingredient_category:6l193z7n8xie5wzcftk5, name: 'Oils & Condiments' }, { id: ingredient_category:6r4xcrprv1xittgf7jb3, name: 'Fruits' }, { id: ingredient_category:708ruu9h2tchj963g788, name: 'Vegetables' }, { id: ingredient_category:dbd8gsxkymvrar9m51zh, name: 'Spices & Herbs' }, { id: ingredient_category:qxywzfa6wg7bg8ux978w, name: 'Beverages' } ];

-- ------------------------------
-- TABLE: meal
-- ------------------------------

DEFINE TABLE meal TYPE NORMAL SCHEMAFULL PERMISSIONS NONE;

DEFINE FIELD color ON meal TYPE string PERMISSIONS FULL;
DEFINE FIELD name ON meal TYPE string PERMISSIONS FULL;



-- ------------------------------
-- TABLE DATA: meal
-- ------------------------------

INSERT [ { color: '#f0e68c', id: meal:4vtmbakz8sj1yinzrnol, name: 'Dessert' }, { color: '#ffb347', id: meal:780ud71m7cznuxv18ca8, name: 'Breakfast' }, { color: '#98fb98', id: meal:9cvpii7x1nnhucmqne6u, name: 'Snack' }, { color: '#dda0dd', id: meal:nrq3v4d6ql0oq0da5zbl, name: 'Dinner' }, { color: '#87ceeb', id: meal:r2li359hfvqcbw4lgfdl, name: 'Lunch' }, { color: '#ec6565', id: meal:x0q7sg7lyuaer8a9nkuw, name: 'test' } ];

-- ------------------------------
-- TABLE: recipe
-- ------------------------------

DEFINE TABLE recipe TYPE NORMAL SCHEMAFULL PERMISSIONS NONE;

DEFINE FIELD author ON recipe TYPE record<user> PERMISSIONS FULL;
DEFINE FIELD created_at ON recipe TYPE datetime DEFAULT time::now() PERMISSIONS FULL;
DEFINE FIELD cuisine ON recipe TYPE option<record<cuisine>> PERMISSIONS FULL;
DEFINE FIELD ingredients ON recipe TYPE array<object> DEFAULT [] PERMISSIONS FULL;
DEFINE FIELD ingredients[*] ON recipe TYPE object PERMISSIONS FULL;
DEFINE FIELD ingredients[*].amount ON recipe TYPE option<number> PERMISSIONS FULL;
DEFINE FIELD ingredients[*].description ON recipe TYPE option<string> PERMISSIONS FULL;
DEFINE FIELD ingredients[*].ingredient ON recipe TYPE record<ingredient> PERMISSIONS FULL;
DEFINE FIELD ingredients[*].unit ON recipe TYPE option<record<unit>> PERMISSIONS FULL;
DEFINE FIELD meal ON recipe TYPE array<record<meal>> DEFAULT [] PERMISSIONS FULL;
DEFINE FIELD meal[*] ON recipe TYPE record<meal> PERMISSIONS FULL;
DEFINE FIELD name ON recipe TYPE string PERMISSIONS FULL;
DEFINE FIELD steps ON recipe TYPE array<string> DEFAULT [] PERMISSIONS FULL;
DEFINE FIELD steps[*] ON recipe TYPE string PERMISSIONS FULL;
DEFINE FIELD tags ON recipe TYPE array<record<recipe_tag>> DEFAULT [] PERMISSIONS FULL;
DEFINE FIELD tags[*] ON recipe TYPE record<recipe_tag> PERMISSIONS FULL;
DEFINE FIELD updated_at ON recipe TYPE datetime VALUE time::now() PERMISSIONS FULL;



-- ------------------------------
-- TABLE DATA: recipe
-- ------------------------------

INSERT [ { author: user:1o4s0mdx4t5t8bbt3qk2, created_at: d'2025-08-31T15:56:11.433758882Z', cuisine: cuisine:wr7mbxix6ddo09n8fe1j, id: recipe:8gr60zvbdbf5lqvilm7p, ingredients: [{ amount: 500, description: 'ground beef', ingredient: ingredient:d6oho5h8pr5qqpgq4jui, unit: unit:zck5uf5229eac9zzcsm6 }, { amount: 1, description: 'small onion, diced', ingredient: ingredient:jomn81vjr1uuti6yq322, unit: unit:6lcc96dqgusb8e7o3ado }, { amount: 2, description: 'garlic cloves, minced', ingredient: ingredient:tanhs35fguiqzehurdxe, unit: unit:52v34z858vd6wh7b38zf }, { amount: 1, description: 'bell pepper, diced', ingredient: ingredient:6ir6u5znxrum2tdsc9x7, unit: unit:6lcc96dqgusb8e7o3ado }, { amount: 200, description: 'diced tomatoes', ingredient: ingredient:2s29078zl3tzoa5glip0, unit: unit:zck5uf5229eac9zzcsm6 }, { amount: 2, description: 'for cooking', ingredient: ingredient:3ht19sif4gkj9m799dhi, unit: unit:i18ck9juqsb446300gaq }, { description: 'to taste', ingredient: ingredient:c3zuikeoh4odb0rkpwzo }, { description: 'to taste', ingredient: ingredient:ydygrnlh130uyqh08vfq }], meal: [meal:r2li359hfvqcbw4lgfdl, meal:nrq3v4d6ql0oq0da5zbl], name: 'Beef Tacos', steps: ['Heat oil in a large skillet over medium-high heat', 'Add diced onion and bell pepper, cook for 5 minutes until softened', 'Add minced garlic and cook for another minute', 'Add ground beef and cook, breaking it up, until browned (8-10 minutes)', 'Add diced tomatoes, salt, and pepper', 'Simmer for 10-15 minutes until sauce thickens', 'Warm taco shells according to package instructions', 'Fill shells with beef mixture', 'Serve with your favorite toppings'], tags: [recipe_tag:wbyxkp1a4wm7jpvtsc4a, recipe_tag:8i4jd82wmiyodktv7fj8], updated_at: d'2025-08-31T15:56:11.433819433Z' }, { author: user:1o4s0mdx4t5t8bbt3qk2, created_at: d'2025-08-31T15:55:51.963063010Z', cuisine: cuisine:ezuiprf3bxbf058e55pw, id: recipe:kpravpi4p1018bkeznss, ingredients: [{ amount: 400, description: 'crushed tomatoes for sauce', ingredient: ingredient:2s29078zl3tzoa5glip0, unit: unit:zck5uf5229eac9zzcsm6 }, { amount: 200, description: 'fresh mozzarella, sliced', ingredient: ingredient:ig0527g34zxypjz39q9l, unit: unit:zck5uf5229eac9zzcsm6 }, { description: 'fresh basil leaves', ingredient: ingredient:f9ep4ir98c38ou65bwon }, { amount: 2, description: 'extra virgin olive oil', ingredient: ingredient:3ht19sif4gkj9m799dhi, unit: unit:i18ck9juqsb446300gaq }, { amount: 2, description: 'garlic cloves, minced', ingredient: ingredient:tanhs35fguiqzehurdxe, unit: unit:52v34z858vd6wh7b38zf }, { description: 'to taste', ingredient: ingredient:c3zuikeoh4odb0rkpwzo }, { description: 'to taste', ingredient: ingredient:ydygrnlh130uyqh08vfq }], meal: [meal:r2li359hfvqcbw4lgfdl, meal:nrq3v4d6ql0oq0da5zbl], name: 'Margherita Pizza', steps: ['Preheat oven to 475°F (245°C)', 'Roll out pizza dough on a floured surface', 'Transfer dough to a pizza stone or baking sheet', 'Mix crushed tomatoes with minced garlic, salt, and pepper for sauce', 'Spread sauce evenly over dough, leaving a 1-inch border', 'Drizzle with 1 tablespoon olive oil', 'Arrange mozzarella slices evenly over sauce', 'Bake for 12-15 minutes until crust is golden and cheese is bubbly', 'Remove from oven and immediately top with fresh basil leaves', 'Drizzle with remaining olive oil and serve hot'], tags: [recipe_tag:xpyib0s5l04f566ktku7, recipe_tag:8i4jd82wmiyodktv7fj8], updated_at: d'2025-08-31T15:55:51.963119168Z' }, { author: user:1o4s0mdx4t5t8bbt3qk2, created_at: d'2025-08-31T15:56:28.015354329Z', cuisine: cuisine:sebuiaxtu0nr2xkivpkj, id: recipe:kwcomfhypjw6dy5rkm44, ingredients: [{ amount: 50, description: 'grated mozzarella cheese', ingredient: ingredient:ig0527g34zxypjz39q9l, unit: unit:zck5uf5229eac9zzcsm6 }, { amount: 1, description: 'for cooking', ingredient: ingredient:3ht19sif4gkj9m799dhi, unit: unit:i18ck9juqsb446300gaq }, { description: 'to taste', ingredient: ingredient:c3zuikeoh4odb0rkpwzo }, { description: 'to taste', ingredient: ingredient:ydygrnlh130uyqh08vfq }], meal: [meal:780ud71m7cznuxv18ca8], name: 'Classic French Omelette', steps: ['Crack eggs into a bowl and whisk vigorously until well combined', 'Season with salt and pepper', 'Heat butter in a non-stick pan over medium-low heat', 'Pour in eggs and let them set for about 30 seconds', 'Using a spatula, gently push cooked edges toward center, tilting pan to let uncooked egg flow underneath', 'When eggs are almost set but still slightly wet on top, add cheese to one half', 'Fold omelette in half and slide onto plate', 'Serve immediately while hot'], tags: [recipe_tag:gqf1t7jaqynkccdloh9b, recipe_tag:xpyib0s5l04f566ktku7], updated_at: d'2025-08-31T15:56:28.015394104Z' }, { author: user:1o4s0mdx4t5t8bbt3qk2, created_at: d'2025-08-31T15:55:33.317675037Z', cuisine: cuisine:op12176ds4fyqm8lbcgv, id: recipe:mx7vkcstitkujradq8g4, ingredients: [{ amount: 2, description: 'cooked and cooled rice', ingredient: ingredient:o084zdfk58avr77mf8hj, unit: unit:iwabwne2ijjk0kc1ahkf }, { amount: 300, description: 'diced chicken breast', ingredient: ingredient:x8spri9jy77u6l8f9pnd, unit: unit:zck5uf5229eac9zzcsm6 }, { amount: 1, description: 'medium onion, diced', ingredient: ingredient:jomn81vjr1uuti6yq322, unit: unit:6lcc96dqgusb8e7o3ado }, { amount: 3, description: 'garlic cloves, minced', ingredient: ingredient:tanhs35fguiqzehurdxe, unit: unit:52v34z858vd6wh7b38zf }, { amount: 3, description: 'for cooking', ingredient: ingredient:3ht19sif4gkj9m799dhi, unit: unit:i18ck9juqsb446300gaq }, { description: 'to taste', ingredient: ingredient:c3zuikeoh4odb0rkpwzo }, { description: 'to taste', ingredient: ingredient:ydygrnlh130uyqh08vfq }], meal: [meal:r2li359hfvqcbw4lgfdl, meal:nrq3v4d6ql0oq0da5zbl], name: 'Chicken Fried Rice', steps: ['Heat 2 tablespoons of oil in a large wok or skillet over high heat', 'Add diced chicken and cook until golden brown and cooked through, about 5-6 minutes', 'Push chicken to one side of the pan', 'Add remaining oil and scramble eggs on the empty side', 'Add onion and garlic, stir-fry for 2 minutes until fragrant', 'Add cold rice, breaking up any clumps with a spatula', 'Stir-fry everything together for 3-4 minutes until rice is heated through', 'Season with salt and pepper to taste', 'Serve hot'], tags: [recipe_tag:gqf1t7jaqynkccdloh9b, recipe_tag:8i4jd82wmiyodktv7fj8], updated_at: d'2025-08-31T15:55:33.317738251Z' }, { author: user:1o4s0mdx4t5t8bbt3qk2, created_at: d'2025-08-31T15:54:50.391173900Z', cuisine: cuisine:kd4ewtmdksdskequl9va, id: recipe:rf20fs0lb3wfmc4l7xbu, ingredients: [{ amount: 2, description: 'boneless, skinless chicken breasts', ingredient: ingredient:x8spri9jy77u6l8f9pnd, unit: unit:6lcc96dqgusb8e7o3ado }, { amount: 3, description: 'extra virgin olive oil', ingredient: ingredient:3ht19sif4gkj9m799dhi, unit: unit:i18ck9juqsb446300gaq }, { amount: 2, description: 'garlic cloves, minced', ingredient: ingredient:tanhs35fguiqzehurdxe, unit: unit:52v34z858vd6wh7b38zf }, { amount: 100, description: 'freshly grated', ingredient: ingredient:89zb8gyyjvttp42b9qgx, unit: unit:zck5uf5229eac9zzcsm6 }, { description: 'to taste', ingredient: ingredient:c3zuikeoh4odb0rkpwzo }, { description: 'to taste', ingredient: ingredient:ydygrnlh130uyqh08vfq }], meal: [meal:r2li359hfvqcbw4lgfdl], name: 'Grilled Chicken Caesar Salad', steps: ['Season chicken breasts with salt, pepper, and 1 tablespoon olive oil', 'Grill chicken for 6-7 minutes per side until internal temperature reaches 165°F', 'Let chicken rest for 5 minutes, then slice into strips', 'In a large bowl, whisk together remaining olive oil, minced garlic, and half the Parmesan', 'Add lettuce and toss to coat with dressing', 'Top with sliced chicken and remaining Parmesan', 'Serve immediately'], tags: [recipe_tag:tn26xz3ija82ivwx88op, recipe_tag:gqf1t7jaqynkccdloh9b], updated_at: d'2025-08-31T15:54:50.391224526Z' }, { author: user:1o4s0mdx4t5t8bbt3qk2, created_at: d'2025-08-31T15:54:35.438849978Z', cuisine: cuisine:ezuiprf3bxbf058e55pw, id: recipe:v6rbdbwzkyzgzbp4qrqb, ingredients: [{ amount: 400, description: 'spaghetti pasta', ingredient: ingredient:ykezqetthtd3zmnd132h, unit: unit:zck5uf5229eac9zzcsm6 }, { amount: 500, description: 'lean ground beef', ingredient: ingredient:d6oho5h8pr5qqpgq4jui, unit: unit:zck5uf5229eac9zzcsm6 }, { amount: 1, description: 'large onion, diced', ingredient: ingredient:jomn81vjr1uuti6yq322, unit: unit:6lcc96dqgusb8e7o3ado }, { amount: 3, description: 'garlic cloves, minced', ingredient: ingredient:tanhs35fguiqzehurdxe, unit: unit:52v34z858vd6wh7b38zf }, { amount: 400, description: 'canned crushed tomatoes', ingredient: ingredient:2s29078zl3tzoa5glip0, unit: unit:zck5uf5229eac9zzcsm6 }, { amount: 2, description: 'extra virgin olive oil', ingredient: ingredient:3ht19sif4gkj9m799dhi, unit: unit:i18ck9juqsb446300gaq }, { amount: 50, description: 'freshly grated', ingredient: ingredient:89zb8gyyjvttp42b9qgx, unit: unit:zck5uf5229eac9zzcsm6 }, { description: 'fresh basil leaves', ingredient: ingredient:f9ep4ir98c38ou65bwon }, { description: 'to taste', ingredient: ingredient:c3zuikeoh4odb0rkpwzo }, { description: 'to taste', ingredient: ingredient:ydygrnlh130uyqh08vfq }], meal: [meal:r2li359hfvqcbw4lgfdl, meal:nrq3v4d6ql0oq0da5zbl], name: 'Classic Spaghetti Bolognese', steps: ['Heat olive oil in a large pan over medium heat', 'Add diced onion and cook until translucent, about 5 minutes', 'Add minced garlic and cook for another minute until fragrant', 'Add ground beef and cook, breaking it up with a spoon, until browned', 'Add crushed tomatoes, salt, and pepper. Simmer for 20-25 minutes', 'Meanwhile, cook spaghetti according to package instructions until al dente', 'Drain pasta and serve with bolognese sauce', 'Garnish with fresh basil and grated Parmesan cheese'], tags: [recipe_tag:8i4jd82wmiyodktv7fj8, recipe_tag:gqf1t7jaqynkccdloh9b], updated_at: d'2025-08-31T15:54:35.438918624Z' }, { author: user:1o4s0mdx4t5t8bbt3qk2, created_at: d'2025-08-31T15:56:45.540728145Z', cuisine: cuisine:ezuiprf3bxbf058e55pw, id: recipe:x8gdp92ms31x35hrp5bq, ingredients: [{ amount: 400, description: 'pasta of choice', ingredient: ingredient:ykezqetthtd3zmnd132h, unit: unit:zck5uf5229eac9zzcsm6 }, { amount: 6, description: 'garlic cloves, thinly sliced', ingredient: ingredient:tanhs35fguiqzehurdxe, unit: unit:52v34z858vd6wh7b38zf }, { amount: 100, description: 'freshly grated Parmesan', ingredient: ingredient:89zb8gyyjvttp42b9qgx, unit: unit:zck5uf5229eac9zzcsm6 }, { amount: 4, description: 'extra virgin olive oil', ingredient: ingredient:3ht19sif4gkj9m799dhi, unit: unit:i18ck9juqsb446300gaq }, { description: 'fresh basil for garnish', ingredient: ingredient:f9ep4ir98c38ou65bwon }, { description: 'to taste', ingredient: ingredient:c3zuikeoh4odb0rkpwzo }, { description: 'to taste', ingredient: ingredient:ydygrnlh130uyqh08vfq }], meal: [meal:nrq3v4d6ql0oq0da5zbl], name: 'Garlic Parmesan Pasta', steps: ['Cook pasta according to package instructions until al dente, reserve 1 cup pasta water', 'While pasta cooks, heat olive oil in a large pan over medium heat', 'Add sliced garlic and cook until golden and fragrant, about 2-3 minutes', 'Drain pasta and add to the pan with garlic oil', 'Toss pasta with garlic oil, adding pasta water gradually to create a silky sauce', 'Remove from heat and add half the Parmesan cheese, tossing quickly', 'Season with salt and pepper to taste', 'Serve immediately topped with remaining Parmesan and fresh basil'], tags: [recipe_tag:gqf1t7jaqynkccdloh9b, recipe_tag:xpyib0s5l04f566ktku7, recipe_tag:8i4jd82wmiyodktv7fj8], updated_at: d'2025-08-31T15:56:45.540776856Z' } ];

-- ------------------------------
-- TABLE: recipe_tag
-- ------------------------------

DEFINE TABLE recipe_tag TYPE NORMAL SCHEMAFULL PERMISSIONS NONE;

DEFINE FIELD color ON recipe_tag TYPE string PERMISSIONS FULL;
DEFINE FIELD icon ON recipe_tag TYPE string PERMISSIONS FULL;
DEFINE FIELD name ON recipe_tag TYPE string PERMISSIONS FULL;



-- ------------------------------
-- TABLE DATA: recipe_tag
-- ------------------------------

INSERT [ { color: '#20b2aa', icon: '🥜', id: recipe_tag:1kx9gry02x0lv49e99db, name: 'Gluten-Free' }, { color: '#ffd700', icon: '🧄', id: recipe_tag:8i4jd82wmiyodktv7fj8, name: 'Savory' }, { color: '#ffe66d', icon: '⚡', id: recipe_tag:gqf1t7jaqynkccdloh9b, name: 'Quick' }, { color: '#dda0dd', icon: '❄️', id: recipe_tag:lpq5bsmoyw41ofuis63u, name: 'Cold' }, { color: '#ffa07a', icon: '🍰', id: recipe_tag:tdq830jzkqxizr37k93b, name: 'Sweet' }, { color: '#4ecdc4', icon: '🥗', id: recipe_tag:tn26xz3ija82ivwx88op, name: 'Healthy' }, { color: '#a8e6cf', icon: '🔥', id: recipe_tag:wbyxkp1a4wm7jpvtsc4a, name: 'Spicy' }, { color: '#ff6b6b', icon: '🌱', id: recipe_tag:xpyib0s5l04f566ktku7, name: 'Vegetarian' } ];

-- ------------------------------
-- TABLE: shopping_list
-- ------------------------------

DEFINE TABLE shopping_list TYPE NORMAL SCHEMAFULL PERMISSIONS NONE;

DEFINE FIELD household ON shopping_list TYPE record<household> PERMISSIONS FULL;
DEFINE FIELD items ON shopping_list TYPE array<object> DEFAULT [] PERMISSIONS FULL;
DEFINE FIELD items[*] ON shopping_list TYPE object PERMISSIONS FULL;
DEFINE FIELD items[*].amount ON shopping_list TYPE option<number> PERMISSIONS FULL;
DEFINE FIELD items[*].checked ON shopping_list TYPE bool DEFAULT false PERMISSIONS FULL;
DEFINE FIELD items[*].flagged ON shopping_list TYPE bool DEFAULT false PERMISSIONS FULL;
DEFINE FIELD items[*].ingredient ON shopping_list TYPE record<ingredient> PERMISSIONS FULL;
DEFINE FIELD items[*].unit ON shopping_list TYPE option<record<unit>> PERMISSIONS FULL;
DEFINE FIELD name ON shopping_list TYPE string PERMISSIONS FULL;
DEFINE FIELD updated_at ON shopping_list TYPE datetime VALUE time::now() PERMISSIONS FULL;



-- ------------------------------
-- TABLE DATA: shopping_list
-- ------------------------------


-- ------------------------------
-- TABLE: unit
-- ------------------------------

DEFINE TABLE unit TYPE NORMAL SCHEMAFULL PERMISSIONS NONE;

DEFINE FIELD name ON unit TYPE string PERMISSIONS FULL;



-- ------------------------------
-- TABLE DATA: unit
-- ------------------------------

INSERT [ { id: unit:6lcc96dqgusb8e7o3ado, name: 'piece' }, { id: unit:8sz9upaez211neozm7q6, name: 'liter' }, { id: unit:df7546nxtx356v4cqjrr, name: 'test2' }, { id: unit:e7o0hnpi4k7t36101ukd, name: 'ounce' }, { id: unit:i18ck9juqsb446300gaq, name: 'tablespoon' }, { id: unit:i43v7z02ym97qhe7cd3u, name: 'pound' }, { id: unit:iwabwne2ijjk0kc1ahkf, name: 'cup' }, { id: unit:k5bamkuwpqdtzymq2nwb, name: 'clove' }, { id: unit:pfk03e13eeljgy2gjfs8, name: 'pinch' }, { id: unit:r8d12i4zde15otrnwhzn, name: 'test' }, { id: unit:uvzhzbrs5j4dbkaei428, name: 'kilogram' }, { id: unit:vssyspdxjylzabico6rt, name: 'teaspoon' }, { id: unit:z1pei9oamixcbfngsa0k, name: 'milliliter' }, { id: unit:zck5uf5229eac9zzcsm6, name: 'gram' } ];

-- ------------------------------
-- TABLE: user
-- ------------------------------

DEFINE TABLE user TYPE NORMAL SCHEMAFULL PERMISSIONS NONE;

DEFINE FIELD created_at ON user TYPE datetime DEFAULT time::now() PERMISSIONS FULL;
DEFINE FIELD deleted ON user TYPE bool DEFAULT false PERMISSIONS FULL;
DEFINE FIELD email ON user TYPE string PERMISSIONS FULL;
DEFINE FIELD password ON user TYPE string VALUE crypto::bcrypt::generate($value) PERMISSIONS FULL;
DEFINE FIELD updated_at ON user TYPE datetime VALUE time::now() PERMISSIONS FULL;
DEFINE FIELD username ON user TYPE string PERMISSIONS FULL;

DEFINE INDEX email_unique ON user FIELDS email UNIQUE;


-- ------------------------------
-- TABLE DATA: user
-- ------------------------------

INSERT [ { created_at: d'2025-08-31T15:51:19.881301726Z', deleted: false, email: 'john.doe@example.com', id: user:1o4s0mdx4t5t8bbt3qk2, password: '$2b$12$ANVWgMsI2ARkHjOUAiY7oupO6zssZ5ZMgdMUknl4fb9NFN1JzIVi2', updated_at: d'2025-08-31T17:05:40.137531841Z', username: 'johndoe' } ];

-- ------------------------------
-- TABLE: weekly_plan
-- ------------------------------

DEFINE TABLE weekly_plan TYPE NORMAL SCHEMAFULL PERMISSIONS NONE;

DEFINE FIELD friday ON weekly_plan TYPE object PERMISSIONS FULL;
DEFINE FIELD friday.breakfast ON weekly_plan TYPE object PERMISSIONS FULL;
DEFINE FIELD friday.breakfast.recipes ON weekly_plan TYPE array<record<recipe>> PERMISSIONS FULL;
DEFINE FIELD friday.breakfast.recipes[*] ON weekly_plan TYPE record<recipe> PERMISSIONS FULL;
DEFINE FIELD friday.breakfast.rules ON weekly_plan TYPE array<record<recipe_tag>> PERMISSIONS FULL;
DEFINE FIELD friday.breakfast.rules[*] ON weekly_plan TYPE record<recipe_tag> PERMISSIONS FULL;
DEFINE FIELD friday.dinner ON weekly_plan TYPE object PERMISSIONS FULL;
DEFINE FIELD friday.dinner.recipes ON weekly_plan TYPE array<record<recipe>> PERMISSIONS FULL;
DEFINE FIELD friday.dinner.recipes[*] ON weekly_plan TYPE record<recipe> PERMISSIONS FULL;
DEFINE FIELD friday.dinner.rules ON weekly_plan TYPE array<record<recipe_tag>> PERMISSIONS FULL;
DEFINE FIELD friday.dinner.rules[*] ON weekly_plan TYPE record<recipe_tag> PERMISSIONS FULL;
DEFINE FIELD friday.lunch ON weekly_plan TYPE object PERMISSIONS FULL;
DEFINE FIELD friday.lunch.recipes ON weekly_plan TYPE array<record<recipe>> PERMISSIONS FULL;
DEFINE FIELD friday.lunch.recipes[*] ON weekly_plan TYPE record<recipe> PERMISSIONS FULL;
DEFINE FIELD friday.lunch.rules ON weekly_plan TYPE array<record<recipe_tag>> PERMISSIONS FULL;
DEFINE FIELD friday.lunch.rules[*] ON weekly_plan TYPE record<recipe_tag> PERMISSIONS FULL;
DEFINE FIELD friday.other ON weekly_plan TYPE object PERMISSIONS FULL;
DEFINE FIELD friday.other.recipes ON weekly_plan TYPE array<record<recipe>> PERMISSIONS FULL;
DEFINE FIELD friday.other.recipes[*] ON weekly_plan TYPE record<recipe> PERMISSIONS FULL;
DEFINE FIELD friday.other.rules ON weekly_plan TYPE array<record<recipe_tag>> PERMISSIONS FULL;
DEFINE FIELD friday.other.rules[*] ON weekly_plan TYPE record<recipe_tag> PERMISSIONS FULL;
DEFINE FIELD monday ON weekly_plan TYPE object PERMISSIONS FULL;
DEFINE FIELD monday.breakfast ON weekly_plan TYPE object PERMISSIONS FULL;
DEFINE FIELD monday.breakfast.recipes ON weekly_plan TYPE array<record<recipe>> PERMISSIONS FULL;
DEFINE FIELD monday.breakfast.recipes[*] ON weekly_plan TYPE record<recipe> PERMISSIONS FULL;
DEFINE FIELD monday.breakfast.rules ON weekly_plan TYPE array<record<recipe_tag>> PERMISSIONS FULL;
DEFINE FIELD monday.breakfast.rules[*] ON weekly_plan TYPE record<recipe_tag> PERMISSIONS FULL;
DEFINE FIELD monday.dinner ON weekly_plan TYPE object PERMISSIONS FULL;
DEFINE FIELD monday.dinner.recipes ON weekly_plan TYPE array<record<recipe>> PERMISSIONS FULL;
DEFINE FIELD monday.dinner.recipes[*] ON weekly_plan TYPE record<recipe> PERMISSIONS FULL;
DEFINE FIELD monday.dinner.rules ON weekly_plan TYPE array<record<recipe_tag>> PERMISSIONS FULL;
DEFINE FIELD monday.dinner.rules[*] ON weekly_plan TYPE record<recipe_tag> PERMISSIONS FULL;
DEFINE FIELD monday.lunch ON weekly_plan TYPE object PERMISSIONS FULL;
DEFINE FIELD monday.lunch.recipes ON weekly_plan TYPE array<record<recipe>> PERMISSIONS FULL;
DEFINE FIELD monday.lunch.recipes[*] ON weekly_plan TYPE record<recipe> PERMISSIONS FULL;
DEFINE FIELD monday.lunch.rules ON weekly_plan TYPE array<record<recipe_tag>> PERMISSIONS FULL;
DEFINE FIELD monday.lunch.rules[*] ON weekly_plan TYPE record<recipe_tag> PERMISSIONS FULL;
DEFINE FIELD monday.other ON weekly_plan TYPE object PERMISSIONS FULL;
DEFINE FIELD monday.other.recipes ON weekly_plan TYPE array<record<recipe>> PERMISSIONS FULL;
DEFINE FIELD monday.other.recipes[*] ON weekly_plan TYPE record<recipe> PERMISSIONS FULL;
DEFINE FIELD monday.other.rules ON weekly_plan TYPE array<record<recipe_tag>> PERMISSIONS FULL;
DEFINE FIELD monday.other.rules[*] ON weekly_plan TYPE record<recipe_tag> PERMISSIONS FULL;
DEFINE FIELD name ON weekly_plan TYPE string PERMISSIONS FULL;
DEFINE FIELD saturday ON weekly_plan TYPE object PERMISSIONS FULL;
DEFINE FIELD saturday.breakfast ON weekly_plan TYPE object PERMISSIONS FULL;
DEFINE FIELD saturday.breakfast.recipes ON weekly_plan TYPE array<record<recipe>> PERMISSIONS FULL;
DEFINE FIELD saturday.breakfast.recipes[*] ON weekly_plan TYPE record<recipe> PERMISSIONS FULL;
DEFINE FIELD saturday.breakfast.rules ON weekly_plan TYPE array<record<recipe_tag>> PERMISSIONS FULL;
DEFINE FIELD saturday.breakfast.rules[*] ON weekly_plan TYPE record<recipe_tag> PERMISSIONS FULL;
DEFINE FIELD saturday.dinner ON weekly_plan TYPE object PERMISSIONS FULL;
DEFINE FIELD saturday.dinner.recipes ON weekly_plan TYPE array<record<recipe>> PERMISSIONS FULL;
DEFINE FIELD saturday.dinner.recipes[*] ON weekly_plan TYPE record<recipe> PERMISSIONS FULL;
DEFINE FIELD saturday.dinner.rules ON weekly_plan TYPE array<record<recipe_tag>> PERMISSIONS FULL;
DEFINE FIELD saturday.dinner.rules[*] ON weekly_plan TYPE record<recipe_tag> PERMISSIONS FULL;
DEFINE FIELD saturday.lunch ON weekly_plan TYPE object PERMISSIONS FULL;
DEFINE FIELD saturday.lunch.recipes ON weekly_plan TYPE array<record<recipe>> PERMISSIONS FULL;
DEFINE FIELD saturday.lunch.recipes[*] ON weekly_plan TYPE record<recipe> PERMISSIONS FULL;
DEFINE FIELD saturday.lunch.rules ON weekly_plan TYPE array<record<recipe_tag>> PERMISSIONS FULL;
DEFINE FIELD saturday.lunch.rules[*] ON weekly_plan TYPE record<recipe_tag> PERMISSIONS FULL;
DEFINE FIELD saturday.other ON weekly_plan TYPE object PERMISSIONS FULL;
DEFINE FIELD saturday.other.recipes ON weekly_plan TYPE array<record<recipe>> PERMISSIONS FULL;
DEFINE FIELD saturday.other.recipes[*] ON weekly_plan TYPE record<recipe> PERMISSIONS FULL;
DEFINE FIELD saturday.other.rules ON weekly_plan TYPE array<record<recipe_tag>> PERMISSIONS FULL;
DEFINE FIELD saturday.other.rules[*] ON weekly_plan TYPE record<recipe_tag> PERMISSIONS FULL;
DEFINE FIELD sunday ON weekly_plan TYPE object PERMISSIONS FULL;
DEFINE FIELD sunday.breakfast ON weekly_plan TYPE object PERMISSIONS FULL;
DEFINE FIELD sunday.breakfast.recipes ON weekly_plan TYPE array<record<recipe>> PERMISSIONS FULL;
DEFINE FIELD sunday.breakfast.recipes[*] ON weekly_plan TYPE record<recipe> PERMISSIONS FULL;
DEFINE FIELD sunday.breakfast.rules ON weekly_plan TYPE array<record<recipe_tag>> PERMISSIONS FULL;
DEFINE FIELD sunday.breakfast.rules[*] ON weekly_plan TYPE record<recipe_tag> PERMISSIONS FULL;
DEFINE FIELD sunday.dinner ON weekly_plan TYPE object PERMISSIONS FULL;
DEFINE FIELD sunday.dinner.recipes ON weekly_plan TYPE array<record<recipe>> PERMISSIONS FULL;
DEFINE FIELD sunday.dinner.recipes[*] ON weekly_plan TYPE record<recipe> PERMISSIONS FULL;
DEFINE FIELD sunday.dinner.rules ON weekly_plan TYPE array<record<recipe_tag>> PERMISSIONS FULL;
DEFINE FIELD sunday.dinner.rules[*] ON weekly_plan TYPE record<recipe_tag> PERMISSIONS FULL;
DEFINE FIELD sunday.lunch ON weekly_plan TYPE object PERMISSIONS FULL;
DEFINE FIELD sunday.lunch.recipes ON weekly_plan TYPE array<record<recipe>> PERMISSIONS FULL;
DEFINE FIELD sunday.lunch.recipes[*] ON weekly_plan TYPE record<recipe> PERMISSIONS FULL;
DEFINE FIELD sunday.lunch.rules ON weekly_plan TYPE array<record<recipe_tag>> PERMISSIONS FULL;
DEFINE FIELD sunday.lunch.rules[*] ON weekly_plan TYPE record<recipe_tag> PERMISSIONS FULL;
DEFINE FIELD sunday.other ON weekly_plan TYPE object PERMISSIONS FULL;
DEFINE FIELD sunday.other.recipes ON weekly_plan TYPE array<record<recipe>> PERMISSIONS FULL;
DEFINE FIELD sunday.other.recipes[*] ON weekly_plan TYPE record<recipe> PERMISSIONS FULL;
DEFINE FIELD sunday.other.rules ON weekly_plan TYPE array<record<recipe_tag>> PERMISSIONS FULL;
DEFINE FIELD sunday.other.rules[*] ON weekly_plan TYPE record<recipe_tag> PERMISSIONS FULL;
DEFINE FIELD thursday ON weekly_plan TYPE object PERMISSIONS FULL;
DEFINE FIELD thursday.breakfast ON weekly_plan TYPE object PERMISSIONS FULL;
DEFINE FIELD thursday.breakfast.recipes ON weekly_plan TYPE array<record<recipe>> PERMISSIONS FULL;
DEFINE FIELD thursday.breakfast.recipes[*] ON weekly_plan TYPE record<recipe> PERMISSIONS FULL;
DEFINE FIELD thursday.breakfast.rules ON weekly_plan TYPE array<record<recipe_tag>> PERMISSIONS FULL;
DEFINE FIELD thursday.breakfast.rules[*] ON weekly_plan TYPE record<recipe_tag> PERMISSIONS FULL;
DEFINE FIELD thursday.dinner ON weekly_plan TYPE object PERMISSIONS FULL;
DEFINE FIELD thursday.dinner.recipes ON weekly_plan TYPE array<record<recipe>> PERMISSIONS FULL;
DEFINE FIELD thursday.dinner.recipes[*] ON weekly_plan TYPE record<recipe> PERMISSIONS FULL;
DEFINE FIELD thursday.dinner.rules ON weekly_plan TYPE array<record<recipe_tag>> PERMISSIONS FULL;
DEFINE FIELD thursday.dinner.rules[*] ON weekly_plan TYPE record<recipe_tag> PERMISSIONS FULL;
DEFINE FIELD thursday.lunch ON weekly_plan TYPE object PERMISSIONS FULL;
DEFINE FIELD thursday.lunch.recipes ON weekly_plan TYPE array<record<recipe>> PERMISSIONS FULL;
DEFINE FIELD thursday.lunch.recipes[*] ON weekly_plan TYPE record<recipe> PERMISSIONS FULL;
DEFINE FIELD thursday.lunch.rules ON weekly_plan TYPE array<record<recipe_tag>> PERMISSIONS FULL;
DEFINE FIELD thursday.lunch.rules[*] ON weekly_plan TYPE record<recipe_tag> PERMISSIONS FULL;
DEFINE FIELD thursday.other ON weekly_plan TYPE object PERMISSIONS FULL;
DEFINE FIELD thursday.other.recipes ON weekly_plan TYPE array<record<recipe>> PERMISSIONS FULL;
DEFINE FIELD thursday.other.recipes[*] ON weekly_plan TYPE record<recipe> PERMISSIONS FULL;
DEFINE FIELD thursday.other.rules ON weekly_plan TYPE array<record<recipe_tag>> PERMISSIONS FULL;
DEFINE FIELD thursday.other.rules[*] ON weekly_plan TYPE record<recipe_tag> PERMISSIONS FULL;
DEFINE FIELD tuesday ON weekly_plan TYPE object PERMISSIONS FULL;
DEFINE FIELD tuesday.breakfast ON weekly_plan TYPE object PERMISSIONS FULL;
DEFINE FIELD tuesday.breakfast.recipes ON weekly_plan TYPE array<record<recipe>> PERMISSIONS FULL;
DEFINE FIELD tuesday.breakfast.recipes[*] ON weekly_plan TYPE record<recipe> PERMISSIONS FULL;
DEFINE FIELD tuesday.breakfast.rules ON weekly_plan TYPE array<record<recipe_tag>> PERMISSIONS FULL;
DEFINE FIELD tuesday.breakfast.rules[*] ON weekly_plan TYPE record<recipe_tag> PERMISSIONS FULL;
DEFINE FIELD tuesday.dinner ON weekly_plan TYPE object PERMISSIONS FULL;
DEFINE FIELD tuesday.dinner.recipes ON weekly_plan TYPE array<record<recipe>> PERMISSIONS FULL;
DEFINE FIELD tuesday.dinner.recipes[*] ON weekly_plan TYPE record<recipe> PERMISSIONS FULL;
DEFINE FIELD tuesday.dinner.rules ON weekly_plan TYPE array<record<recipe_tag>> PERMISSIONS FULL;
DEFINE FIELD tuesday.dinner.rules[*] ON weekly_plan TYPE record<recipe_tag> PERMISSIONS FULL;
DEFINE FIELD tuesday.lunch ON weekly_plan TYPE object PERMISSIONS FULL;
DEFINE FIELD tuesday.lunch.recipes ON weekly_plan TYPE array<record<recipe>> PERMISSIONS FULL;
DEFINE FIELD tuesday.lunch.recipes[*] ON weekly_plan TYPE record<recipe> PERMISSIONS FULL;
DEFINE FIELD tuesday.lunch.rules ON weekly_plan TYPE array<record<recipe_tag>> PERMISSIONS FULL;
DEFINE FIELD tuesday.lunch.rules[*] ON weekly_plan TYPE record<recipe_tag> PERMISSIONS FULL;
DEFINE FIELD tuesday.other ON weekly_plan TYPE object PERMISSIONS FULL;
DEFINE FIELD tuesday.other.recipes ON weekly_plan TYPE array<record<recipe>> PERMISSIONS FULL;
DEFINE FIELD tuesday.other.recipes[*] ON weekly_plan TYPE record<recipe> PERMISSIONS FULL;
DEFINE FIELD tuesday.other.rules ON weekly_plan TYPE array<record<recipe_tag>> PERMISSIONS FULL;
DEFINE FIELD tuesday.other.rules[*] ON weekly_plan TYPE record<recipe_tag> PERMISSIONS FULL;
DEFINE FIELD wednesday ON weekly_plan TYPE object PERMISSIONS FULL;
DEFINE FIELD wednesday.breakfast ON weekly_plan TYPE object PERMISSIONS FULL;
DEFINE FIELD wednesday.breakfast.recipes ON weekly_plan TYPE array<record<recipe>> PERMISSIONS FULL;
DEFINE FIELD wednesday.breakfast.recipes[*] ON weekly_plan TYPE record<recipe> PERMISSIONS FULL;
DEFINE FIELD wednesday.breakfast.rules ON weekly_plan TYPE array<record<recipe_tag>> PERMISSIONS FULL;
DEFINE FIELD wednesday.breakfast.rules[*] ON weekly_plan TYPE record<recipe_tag> PERMISSIONS FULL;
DEFINE FIELD wednesday.dinner ON weekly_plan TYPE object PERMISSIONS FULL;
DEFINE FIELD wednesday.dinner.recipes ON weekly_plan TYPE array<record<recipe>> PERMISSIONS FULL;
DEFINE FIELD wednesday.dinner.recipes[*] ON weekly_plan TYPE record<recipe> PERMISSIONS FULL;
DEFINE FIELD wednesday.dinner.rules ON weekly_plan TYPE array<record<recipe_tag>> PERMISSIONS FULL;
DEFINE FIELD wednesday.dinner.rules[*] ON weekly_plan TYPE record<recipe_tag> PERMISSIONS FULL;
DEFINE FIELD wednesday.lunch ON weekly_plan TYPE object PERMISSIONS FULL;
DEFINE FIELD wednesday.lunch.recipes ON weekly_plan TYPE array<record<recipe>> PERMISSIONS FULL;
DEFINE FIELD wednesday.lunch.recipes[*] ON weekly_plan TYPE record<recipe> PERMISSIONS FULL;
DEFINE FIELD wednesday.lunch.rules ON weekly_plan TYPE array<record<recipe_tag>> PERMISSIONS FULL;
DEFINE FIELD wednesday.lunch.rules[*] ON weekly_plan TYPE record<recipe_tag> PERMISSIONS FULL;
DEFINE FIELD wednesday.other ON weekly_plan TYPE object PERMISSIONS FULL;
DEFINE FIELD wednesday.other.recipes ON weekly_plan TYPE array<record<recipe>> PERMISSIONS FULL;
DEFINE FIELD wednesday.other.recipes[*] ON weekly_plan TYPE record<recipe> PERMISSIONS FULL;
DEFINE FIELD wednesday.other.rules ON weekly_plan TYPE array<record<recipe_tag>> PERMISSIONS FULL;
DEFINE FIELD wednesday.other.rules[*] ON weekly_plan TYPE record<recipe_tag> PERMISSIONS FULL;



-- ------------------------------
-- TABLE DATA: weekly_plan
-- ------------------------------



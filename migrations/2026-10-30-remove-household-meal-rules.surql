-- The fields go first: `meal_rules` is a non-optional object, so it can't be unset while defined.
BEGIN TRANSACTION;

REMOVE FIELD meal_rules.breakfast ON household;
REMOVE FIELD meal_rules.lunch ON household;
REMOVE FIELD meal_rules.dinner ON household;
REMOVE FIELD meal_rules.snack ON household;
REMOVE FIELD meal_rules ON household;

UPDATE household UNSET meal_rules WHERE meal_rules != NONE;

COMMIT TRANSACTION;

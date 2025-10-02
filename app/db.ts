import { RecordId, Duration, Uuid, Decimal } from "surrealdb";

// ---------- TABLE TYPES ----------
export type InCuisine = {
  id?: RecordId<"cuisine">,
  color: string,
  flag?: string | undefined,
  household: Required<InHousehold>['id'],
  name: string,
}

export type OutCuisine = {
  id: RecordId<"cuisine">,
  color: string,
  flag?: string | undefined,
  household: OutHousehold,
  name: string,
}

export type InHousehold = {
  id?: RecordId<"household">,
  created_at?: Date | string,
  language?: 'en' | 'hu',
  name: string,
  updated_at: Date | string,
}

export type OutHousehold = {
  id: RecordId<"household">,
  created_at: string,
  language: 'en' | 'hu',
  name: string,
  updated_at: string,
}

export type InIngredient = {
  id?: RecordId<"ingredient">,
  category?: Required<InIngredientCategory>['id'] | undefined,
  household: Required<InHousehold>['id'],
  name: string,
  skip_from_shopping_list?: boolean,
}

export type OutIngredient = {
  id: RecordId<"ingredient">,
  category?: OutIngredientCategory | undefined,
  household: OutHousehold,
  name: string,
  skip_from_shopping_list: boolean,
}

export type InIngredientCategory = {
  id?: RecordId<"ingredient_category">,
  household: Required<InHousehold>['id'],
  name: string,
}

export type OutIngredientCategory = {
  id: RecordId<"ingredient_category">,
  household: OutHousehold,
  name: string,
}

export type InMeal = {
  id?: RecordId<"meal">,
  color: string,
  household: Required<InHousehold>['id'],
  name: string,
}

export type OutMeal = {
  id: RecordId<"meal">,
  color: string,
  household: OutHousehold,
  name: string,
}

export type InMealPlan = {
  id?: RecordId<"meal_plan">,
  household: Required<InHousehold>['id'],
  recipes: Array<Required<InRecipe>['id']>,
  rules: Array<Required<InRecipeTag>['id']>,
}

export type OutMealPlan = {
  id: RecordId<"meal_plan">,
  household: OutHousehold,
  recipes: Array<OutRecipe>,
  rules: Array<OutRecipeTag>,
}

export type InMealPlanDay = {
  id?: RecordId<"meal_plan_day">,
  breakfast: Required<InMealPlan>['id'],
  dinner: Required<InMealPlan>['id'],
  household: Required<InHousehold>['id'],
  lunch: Required<InMealPlan>['id'],
  other: Required<InMealPlan>['id'],
}

export type OutMealPlanDay = {
  id: RecordId<"meal_plan_day">,
  breakfast: OutMealPlan,
  dinner: OutMealPlan,
  household: OutHousehold,
  lunch: OutMealPlan,
  other: OutMealPlan,
}

export type InMember = {
  id?: RecordId<"member">,
  in: Required<InUser>['id'],
  out: Required<InHousehold>['id'],
  role: 'owner' | 'writer' | 'guest',
}

export type OutMember = {
  id: RecordId<"member">,
  in: OutUser,
  out: OutHousehold,
  role: 'owner' | 'writer' | 'guest',
}

export type InRecipe = {
  id?: RecordId<"recipe">,
  author: Required<InUser>['id'],
  cooking_time_minutes?: number | undefined,
  created_at?: Date | string,
  cuisine?: Required<InCuisine>['id'] | undefined,
  household: Required<InHousehold>['id'],
  image?: ArrayBuffer | undefined,
  image_blur_hash?: string | undefined,
  ingredients?: Array<{
    amount?: number | undefined,
    description?: string | undefined,
    ingredient: Required<InIngredient>['id'],
    unit?: Required<InUnit>['id'] | undefined,
  }>,
  meal?: Array<Required<InMeal>['id']>,
  name: string,
  portions?: number | undefined,
  steps?: Array<string>,
  tags?: Array<Required<InRecipeTag>['id']>,
  updated_at: Date | string,
}

export type OutRecipe = {
  id: RecordId<"recipe">,
  author: OutUser,
  cooking_time_minutes?: number | undefined,
  created_at: string,
  cuisine?: OutCuisine | undefined,
  household: OutHousehold,
  image?: ArrayBuffer | undefined,
  image_blur_hash?: string | undefined,
  ingredients: Array<{
    amount?: number | undefined,
    description?: string | undefined,
    ingredient: OutIngredient,
    unit?: OutUnit | undefined,
  }>,
  meal: Array<OutMeal>,
  name: string,
  portions?: number | undefined,
  steps: Array<string>,
  tags: Array<OutRecipeTag>,
  updated_at: string,
}

export type InRecipeTag = {
  id?: RecordId<"recipe_tag">,
  color: string,
  household: Required<InHousehold>['id'],
  icon?: string | undefined,
  name: string,
}

export type OutRecipeTag = {
  id: RecordId<"recipe_tag">,
  color: string,
  household: OutHousehold,
  icon?: string | undefined,
  name: string,
}

export type InShop = {
  id?: RecordId<"shop">,
  categories: Array<Required<InIngredientCategory>['id']>,
  household: Required<InHousehold>['id'],
  name: string,
}

export type OutShop = {
  id: RecordId<"shop">,
  categories: Array<OutIngredientCategory>,
  household: OutHousehold,
  name: string,
}

export type InShoppingList = {
  id?: RecordId<"shopping_list">,
  household: Required<InHousehold>['id'],
  items?: Array<{
    amount?: number | undefined,
    category?: Required<InIngredientCategory>['id'] | undefined,
    checked?: boolean,
    ingredient: Required<InIngredient>['id'],
    recipe?: Required<InRecipe>['id'] | undefined,
    unit?: Required<InUnit>['id'] | undefined,
  }>,
  name: string,
  shop?: Required<InShop>['id'] | undefined,
  updated_at: Date | string,
}

export type OutShoppingList = {
  id: RecordId<"shopping_list">,
  household: OutHousehold,
  items: Array<{
    amount?: number | undefined,
    category?: OutIngredientCategory | undefined,
    checked: boolean,
    ingredient: OutIngredient,
    recipe?: OutRecipe | undefined,
    unit?: OutUnit | undefined,
  }>,
  name: string,
  shop?: OutShop | undefined,
  updated_at: string,
}

export type InUnit = {
  id?: RecordId<"unit">,
  household: Required<InHousehold>['id'],
  name: string,
}

export type OutUnit = {
  id: RecordId<"unit">,
  household: OutHousehold,
  name: string,
}

export type InUser = {
  id?: RecordId<"user">,
  created_at?: Date | string,
  deleted?: boolean,
  email: string,
  password: string,
  updated_at: Date | string,
  username: string,
}

export type OutUser = {
  id: RecordId<"user">,
  created_at: string,
  deleted: boolean,
  email: string,
  password: string,
  updated_at: string,
  username: string,
}

export type InWeeklyPlan = {
  id?: RecordId<"weekly_plan">,
  friday: Required<InMealPlanDay>['id'],
  household: Required<InHousehold>['id'],
  monday: Required<InMealPlanDay>['id'],
  name: string,
  saturday: Required<InMealPlanDay>['id'],
  sunday: Required<InMealPlanDay>['id'],
  thursday: Required<InMealPlanDay>['id'],
  tuesday: Required<InMealPlanDay>['id'],
  wednesday: Required<InMealPlanDay>['id'],
}

export type OutWeeklyPlan = {
  id: RecordId<"weekly_plan">,
  friday: OutMealPlanDay,
  household: OutHousehold,
  monday: OutMealPlanDay,
  name: string,
  saturday: OutMealPlanDay,
  sunday: OutMealPlanDay,
  thursday: OutMealPlanDay,
  tuesday: OutMealPlanDay,
  wednesday: OutMealPlanDay,
}

// ---------- TABLE META STRUCTURE ----------
export const tables = {
  "cuisine": {
    "fields": {
      "color": {
        "type": {
          "name": "string"
        }
      },
      "flag": {
        "type": {
          "name": "option",
          "inner": {
            "name": "string"
          }
        }
      },
      "household": {
        "type": {
          "name": "record",
          "tables": [
            "household"
          ]
        }
      },
      "name": {
        "type": {
          "name": "string"
        }
      }
    }
  },
  "household": {
    "fields": {
      "created_at": {
        "type": {
          "name": "date"
        },
        "hasDefault": true
      },
      "language": {
        "type": {
          "name": "union",
          "enum": "string",
          "variants": [
            "en",
            "hu"
          ]
        },
        "hasDefault": true
      },
      "name": {
        "type": {
          "name": "string"
        }
      },
      "updated_at": {
        "type": {
          "name": "date"
        }
      }
    }
  },
  "ingredient": {
    "fields": {
      "category": {
        "type": {
          "name": "option",
          "inner": {
            "name": "record",
            "tables": [
              "ingredient_category"
            ]
          }
        }
      },
      "household": {
        "type": {
          "name": "record",
          "tables": [
            "household"
          ]
        }
      },
      "name": {
        "type": {
          "name": "string"
        }
      },
      "skip_from_shopping_list": {
        "type": {
          "name": "boolean"
        },
        "hasDefault": true
      }
    }
  },
  "ingredient_category": {
    "fields": {
      "household": {
        "type": {
          "name": "record",
          "tables": [
            "household"
          ]
        }
      },
      "name": {
        "type": {
          "name": "string"
        }
      }
    }
  },
  "meal": {
    "fields": {
      "color": {
        "type": {
          "name": "string"
        }
      },
      "household": {
        "type": {
          "name": "record",
          "tables": [
            "household"
          ]
        }
      },
      "name": {
        "type": {
          "name": "string"
        }
      }
    }
  },
  "meal_plan": {
    "fields": {
      "household": {
        "type": {
          "name": "record",
          "tables": [
            "household"
          ]
        }
      },
      "recipes": {
        "type": {
          "name": "array",
          "item": {
            "name": "record",
            "tables": [
              "recipe"
            ]
          }
        }
      },
      "rules": {
        "type": {
          "name": "array",
          "item": {
            "name": "record",
            "tables": [
              "recipe_tag"
            ]
          }
        }
      }
    }
  },
  "meal_plan_day": {
    "fields": {
      "breakfast": {
        "type": {
          "name": "record",
          "tables": [
            "meal_plan"
          ]
        }
      },
      "dinner": {
        "type": {
          "name": "record",
          "tables": [
            "meal_plan"
          ]
        }
      },
      "household": {
        "type": {
          "name": "record",
          "tables": [
            "household"
          ]
        }
      },
      "lunch": {
        "type": {
          "name": "record",
          "tables": [
            "meal_plan"
          ]
        }
      },
      "other": {
        "type": {
          "name": "record",
          "tables": [
            "meal_plan"
          ]
        }
      }
    }
  },
  "member": {
    "fields": {
      "in": {
        "type": {
          "name": "record",
          "tables": [
            "user"
          ]
        }
      },
      "out": {
        "type": {
          "name": "record",
          "tables": [
            "household"
          ]
        }
      },
      "role": {
        "type": {
          "name": "union",
          "enum": "string",
          "variants": [
            "owner",
            "writer",
            "guest"
          ]
        }
      }
    }
  },
  "recipe": {
    "fields": {
      "author": {
        "type": {
          "name": "record",
          "tables": [
            "user"
          ]
        }
      },
      "cooking_time_minutes": {
        "type": {
          "name": "option",
          "inner": {
            "name": "number"
          }
        }
      },
      "created_at": {
        "type": {
          "name": "date"
        },
        "hasDefault": true
      },
      "cuisine": {
        "type": {
          "name": "option",
          "inner": {
            "name": "record",
            "tables": [
              "cuisine"
            ]
          }
        }
      },
      "household": {
        "type": {
          "name": "record",
          "tables": [
            "household"
          ]
        }
      },
      "image": {
        "type": {
          "name": "option",
          "inner": {
            "name": "bytes"
          }
        }
      },
      "image_blur_hash": {
        "type": {
          "name": "option",
          "inner": {
            "name": "string"
          }
        }
      },
      "ingredients": {
        "type": {
          "name": "array",
          "item": {
            "name": "object",
            "fields": {
              "amount": {
                "type": {
                  "name": "option",
                  "inner": {
                    "name": "number"
                  }
                }
              },
              "description": {
                "type": {
                  "name": "option",
                  "inner": {
                    "name": "string"
                  }
                }
              },
              "ingredient": {
                "type": {
                  "name": "record",
                  "tables": [
                    "ingredient"
                  ]
                }
              },
              "unit": {
                "type": {
                  "name": "option",
                  "inner": {
                    "name": "record",
                    "tables": [
                      "unit"
                    ]
                  }
                }
              }
            }
          }
        },
        "hasDefault": true
      },
      "meal": {
        "type": {
          "name": "array",
          "item": {
            "name": "record",
            "tables": [
              "meal"
            ]
          }
        },
        "hasDefault": true
      },
      "name": {
        "type": {
          "name": "string"
        }
      },
      "portions": {
        "type": {
          "name": "option",
          "inner": {
            "name": "number"
          }
        }
      },
      "steps": {
        "type": {
          "name": "array",
          "item": {
            "name": "string"
          }
        },
        "hasDefault": true
      },
      "tags": {
        "type": {
          "name": "array",
          "item": {
            "name": "record",
            "tables": [
              "recipe_tag"
            ]
          }
        },
        "hasDefault": true
      },
      "updated_at": {
        "type": {
          "name": "date"
        }
      }
    }
  },
  "recipe_tag": {
    "fields": {
      "color": {
        "type": {
          "name": "string"
        }
      },
      "household": {
        "type": {
          "name": "record",
          "tables": [
            "household"
          ]
        }
      },
      "icon": {
        "type": {
          "name": "option",
          "inner": {
            "name": "string"
          }
        }
      },
      "name": {
        "type": {
          "name": "string"
        }
      }
    }
  },
  "shop": {
    "fields": {
      "categories": {
        "type": {
          "name": "array",
          "item": {
            "name": "record",
            "tables": [
              "ingredient_category"
            ]
          }
        }
      },
      "household": {
        "type": {
          "name": "record",
          "tables": [
            "household"
          ]
        }
      },
      "name": {
        "type": {
          "name": "string"
        }
      }
    }
  },
  "shopping_list": {
    "fields": {
      "household": {
        "type": {
          "name": "record",
          "tables": [
            "household"
          ]
        }
      },
      "items": {
        "type": {
          "name": "array",
          "item": {
            "name": "object",
            "fields": {
              "amount": {
                "type": {
                  "name": "option",
                  "inner": {
                    "name": "number"
                  }
                }
              },
              "category": {
                "type": {
                  "name": "option",
                  "inner": {
                    "name": "record",
                    "tables": [
                      "ingredient_category"
                    ]
                  }
                }
              },
              "checked": {
                "type": {
                  "name": "boolean"
                },
                "hasDefault": true
              },
              "ingredient": {
                "type": {
                  "name": "record",
                  "tables": [
                    "ingredient"
                  ]
                }
              },
              "recipe": {
                "type": {
                  "name": "option",
                  "inner": {
                    "name": "record",
                    "tables": [
                      "recipe"
                    ]
                  }
                }
              },
              "unit": {
                "type": {
                  "name": "option",
                  "inner": {
                    "name": "record",
                    "tables": [
                      "unit"
                    ]
                  }
                }
              }
            }
          }
        },
        "hasDefault": true
      },
      "name": {
        "type": {
          "name": "string"
        }
      },
      "shop": {
        "type": {
          "name": "option",
          "inner": {
            "name": "record",
            "tables": [
              "shop"
            ]
          }
        }
      },
      "updated_at": {
        "type": {
          "name": "date"
        }
      }
    }
  },
  "unit": {
    "fields": {
      "household": {
        "type": {
          "name": "record",
          "tables": [
            "household"
          ]
        }
      },
      "name": {
        "type": {
          "name": "string"
        }
      }
    }
  },
  "user": {
    "fields": {
      "created_at": {
        "type": {
          "name": "date"
        },
        "hasDefault": true
      },
      "deleted": {
        "type": {
          "name": "boolean"
        },
        "hasDefault": true
      },
      "email": {
        "type": {
          "name": "string"
        }
      },
      "password": {
        "type": {
          "name": "string"
        }
      },
      "updated_at": {
        "type": {
          "name": "date"
        }
      },
      "username": {
        "type": {
          "name": "string"
        }
      }
    }
  },
  "weekly_plan": {
    "fields": {
      "friday": {
        "type": {
          "name": "record",
          "tables": [
            "meal_plan_day"
          ]
        }
      },
      "household": {
        "type": {
          "name": "record",
          "tables": [
            "household"
          ]
        }
      },
      "monday": {
        "type": {
          "name": "record",
          "tables": [
            "meal_plan_day"
          ]
        }
      },
      "name": {
        "type": {
          "name": "string"
        }
      },
      "saturday": {
        "type": {
          "name": "record",
          "tables": [
            "meal_plan_day"
          ]
        }
      },
      "sunday": {
        "type": {
          "name": "record",
          "tables": [
            "meal_plan_day"
          ]
        }
      },
      "thursday": {
        "type": {
          "name": "record",
          "tables": [
            "meal_plan_day"
          ]
        }
      },
      "tuesday": {
        "type": {
          "name": "record",
          "tables": [
            "meal_plan_day"
          ]
        }
      },
      "wednesday": {
        "type": {
          "name": "record",
          "tables": [
            "meal_plan_day"
          ]
        }
      }
    }
  }
} as const satisfies Record<string, TableMeta>

// ---------- TABLE META TYPES ----------
export type Tables = Record<string, TableMeta>;
export type Fields = Record<string, FieldMeta>;

export type TableMeta = {
  fields: Fields;
  comment?: string;
};

export type FieldMeta = {
  comment?: string;
  type: FieldType;
  hasDefault?: true;
};

export type FieldType =
  | FieldTypes.Simple
  | FieldTypes.Option
  | FieldTypes.Object
  | FieldTypes.Record
  | FieldTypes.Array
  | FieldTypes.Union
  | FieldTypes.StringEnumUnion
  | FieldTypes.NumberEnumUnion
  | FieldTypes.LiteralNumber
  | FieldTypes.LiteralString
  | FieldTypes.LiteralArray;

export namespace FieldTypes {
  export type Simple = {
    name: "any" | "null" | "boolean" | "string" | "number" | "decimal" | "date" | "duration" | "bytes" | "uuid";
  };

  export type Option = {
    name: "option";
    inner: FieldType;
  };

  export type Object = {
    name: "object";
    fields: null | Fields;
  };

  export type Record = {
    name: "record";
    tables: string[];
  };

  export type Array = {
    name: "array";
    item: FieldType;
  };

  export type Union = {
    name: "union";
    variants: FieldType[];
  };

  export type StringEnumUnion = {
    name: "union";
    enum: "string";
    variants: string[];
  };

  export type NumberEnumUnion = {
    name: "union";
    enum: "number";
    variants: number[];
  };

  export type LiteralNumber = {
    name: "literal";
    kind: "number";
    value: number;
  };

  export type LiteralString = {
    name: "literal";
    kind: "string";
    value: string;
  };

  export type LiteralArray = {
    name: "literal";
    kind: "array";
    items: FieldType[];
  };
}

export type TableMetaFromDb = TableMeta & {
  id: string;
};


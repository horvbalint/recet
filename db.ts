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
  name: string,
  updated_at: Date | string,
}

export type OutHousehold = {
  id: RecordId<"household">,
  created_at: string,
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
  created_at?: Date | string,
  cuisine?: Required<InCuisine>['id'] | undefined,
  household: Required<InHousehold>['id'],
  ingredients?: Array<{
    amount?: number | undefined,
    description?: string | undefined,
    ingredient: Required<InIngredient>['id'],
    unit?: Required<InUnit>['id'] | undefined,
  }>,
  meal?: Array<Required<InMeal>['id']>,
  name: string,
  steps?: Array<string>,
  tags?: Array<Required<InRecipeTag>['id']>,
  updated_at: Date | string,
}

export type OutRecipe = {
  id: RecordId<"recipe">,
  author: OutUser,
  created_at: string,
  cuisine?: OutCuisine | undefined,
  household: OutHousehold,
  ingredients: Array<{
    amount?: number | undefined,
    description?: string | undefined,
    ingredient: OutIngredient,
    unit?: OutUnit | undefined,
  }>,
  meal: Array<OutMeal>,
  name: string,
  steps: Array<string>,
  tags: Array<OutRecipeTag>,
  updated_at: string,
}

export type InRecipeTag = {
  id?: RecordId<"recipe_tag">,
  color: string,
  household: Required<InHousehold>['id'],
  icon: string,
  name: string,
}

export type OutRecipeTag = {
  id: RecordId<"recipe_tag">,
  color: string,
  household: OutHousehold,
  icon: string,
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
  friday: {
    breakfast: {
      recipes: Array<Required<InRecipe>['id']>,
      rules: Array<Required<InRecipeTag>['id']>,
    },
    dinner: {
      recipes: Array<Required<InRecipe>['id']>,
      rules: Array<Required<InRecipeTag>['id']>,
    },
    lunch: {
      recipes: Array<Required<InRecipe>['id']>,
      rules: Array<Required<InRecipeTag>['id']>,
    },
    other: {
      recipes: Array<Required<InRecipe>['id']>,
      rules: Array<Required<InRecipeTag>['id']>,
    },
  },
  household: Required<InHousehold>['id'],
  monday: {
    breakfast: {
      recipes: Array<Required<InRecipe>['id']>,
      rules: Array<Required<InRecipeTag>['id']>,
    },
    dinner: {
      recipes: Array<Required<InRecipe>['id']>,
      rules: Array<Required<InRecipeTag>['id']>,
    },
    lunch: {
      recipes: Array<Required<InRecipe>['id']>,
      rules: Array<Required<InRecipeTag>['id']>,
    },
    other: {
      recipes: Array<Required<InRecipe>['id']>,
      rules: Array<Required<InRecipeTag>['id']>,
    },
  },
  name: string,
  saturday: {
    breakfast: {
      recipes: Array<Required<InRecipe>['id']>,
      rules: Array<Required<InRecipeTag>['id']>,
    },
    dinner: {
      recipes: Array<Required<InRecipe>['id']>,
      rules: Array<Required<InRecipeTag>['id']>,
    },
    lunch: {
      recipes: Array<Required<InRecipe>['id']>,
      rules: Array<Required<InRecipeTag>['id']>,
    },
    other: {
      recipes: Array<Required<InRecipe>['id']>,
      rules: Array<Required<InRecipeTag>['id']>,
    },
  },
  sunday: {
    breakfast: {
      recipes: Array<Required<InRecipe>['id']>,
      rules: Array<Required<InRecipeTag>['id']>,
    },
    dinner: {
      recipes: Array<Required<InRecipe>['id']>,
      rules: Array<Required<InRecipeTag>['id']>,
    },
    lunch: {
      recipes: Array<Required<InRecipe>['id']>,
      rules: Array<Required<InRecipeTag>['id']>,
    },
    other: {
      recipes: Array<Required<InRecipe>['id']>,
      rules: Array<Required<InRecipeTag>['id']>,
    },
  },
  thursday: {
    breakfast: {
      recipes: Array<Required<InRecipe>['id']>,
      rules: Array<Required<InRecipeTag>['id']>,
    },
    dinner: {
      recipes: Array<Required<InRecipe>['id']>,
      rules: Array<Required<InRecipeTag>['id']>,
    },
    lunch: {
      recipes: Array<Required<InRecipe>['id']>,
      rules: Array<Required<InRecipeTag>['id']>,
    },
    other: {
      recipes: Array<Required<InRecipe>['id']>,
      rules: Array<Required<InRecipeTag>['id']>,
    },
  },
  tuesday: {
    breakfast: {
      recipes: Array<Required<InRecipe>['id']>,
      rules: Array<Required<InRecipeTag>['id']>,
    },
    dinner: {
      recipes: Array<Required<InRecipe>['id']>,
      rules: Array<Required<InRecipeTag>['id']>,
    },
    lunch: {
      recipes: Array<Required<InRecipe>['id']>,
      rules: Array<Required<InRecipeTag>['id']>,
    },
    other: {
      recipes: Array<Required<InRecipe>['id']>,
      rules: Array<Required<InRecipeTag>['id']>,
    },
  },
  wednesday: {
    breakfast: {
      recipes: Array<Required<InRecipe>['id']>,
      rules: Array<Required<InRecipeTag>['id']>,
    },
    dinner: {
      recipes: Array<Required<InRecipe>['id']>,
      rules: Array<Required<InRecipeTag>['id']>,
    },
    lunch: {
      recipes: Array<Required<InRecipe>['id']>,
      rules: Array<Required<InRecipeTag>['id']>,
    },
    other: {
      recipes: Array<Required<InRecipe>['id']>,
      rules: Array<Required<InRecipeTag>['id']>,
    },
  },
}

export type OutWeeklyPlan = {
  id: RecordId<"weekly_plan">,
  friday: {
    breakfast: {
      recipes: Array<OutRecipe>,
      rules: Array<OutRecipeTag>,
    },
    dinner: {
      recipes: Array<OutRecipe>,
      rules: Array<OutRecipeTag>,
    },
    lunch: {
      recipes: Array<OutRecipe>,
      rules: Array<OutRecipeTag>,
    },
    other: {
      recipes: Array<OutRecipe>,
      rules: Array<OutRecipeTag>,
    },
  },
  household: OutHousehold,
  monday: {
    breakfast: {
      recipes: Array<OutRecipe>,
      rules: Array<OutRecipeTag>,
    },
    dinner: {
      recipes: Array<OutRecipe>,
      rules: Array<OutRecipeTag>,
    },
    lunch: {
      recipes: Array<OutRecipe>,
      rules: Array<OutRecipeTag>,
    },
    other: {
      recipes: Array<OutRecipe>,
      rules: Array<OutRecipeTag>,
    },
  },
  name: string,
  saturday: {
    breakfast: {
      recipes: Array<OutRecipe>,
      rules: Array<OutRecipeTag>,
    },
    dinner: {
      recipes: Array<OutRecipe>,
      rules: Array<OutRecipeTag>,
    },
    lunch: {
      recipes: Array<OutRecipe>,
      rules: Array<OutRecipeTag>,
    },
    other: {
      recipes: Array<OutRecipe>,
      rules: Array<OutRecipeTag>,
    },
  },
  sunday: {
    breakfast: {
      recipes: Array<OutRecipe>,
      rules: Array<OutRecipeTag>,
    },
    dinner: {
      recipes: Array<OutRecipe>,
      rules: Array<OutRecipeTag>,
    },
    lunch: {
      recipes: Array<OutRecipe>,
      rules: Array<OutRecipeTag>,
    },
    other: {
      recipes: Array<OutRecipe>,
      rules: Array<OutRecipeTag>,
    },
  },
  thursday: {
    breakfast: {
      recipes: Array<OutRecipe>,
      rules: Array<OutRecipeTag>,
    },
    dinner: {
      recipes: Array<OutRecipe>,
      rules: Array<OutRecipeTag>,
    },
    lunch: {
      recipes: Array<OutRecipe>,
      rules: Array<OutRecipeTag>,
    },
    other: {
      recipes: Array<OutRecipe>,
      rules: Array<OutRecipeTag>,
    },
  },
  tuesday: {
    breakfast: {
      recipes: Array<OutRecipe>,
      rules: Array<OutRecipeTag>,
    },
    dinner: {
      recipes: Array<OutRecipe>,
      rules: Array<OutRecipeTag>,
    },
    lunch: {
      recipes: Array<OutRecipe>,
      rules: Array<OutRecipeTag>,
    },
    other: {
      recipes: Array<OutRecipe>,
      rules: Array<OutRecipeTag>,
    },
  },
  wednesday: {
    breakfast: {
      recipes: Array<OutRecipe>,
      rules: Array<OutRecipeTag>,
    },
    dinner: {
      recipes: Array<OutRecipe>,
      rules: Array<OutRecipeTag>,
    },
    lunch: {
      recipes: Array<OutRecipe>,
      rules: Array<OutRecipeTag>,
    },
    other: {
      recipes: Array<OutRecipe>,
      rules: Array<OutRecipeTag>,
    },
  },
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
          "name": "string"
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
          "name": "object",
          "fields": {
            "breakfast": {
              "type": {
                "name": "object",
                "fields": {
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
              }
            },
            "dinner": {
              "type": {
                "name": "object",
                "fields": {
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
              }
            },
            "lunch": {
              "type": {
                "name": "object",
                "fields": {
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
              }
            },
            "other": {
              "type": {
                "name": "object",
                "fields": {
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
              }
            }
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
      "monday": {
        "type": {
          "name": "object",
          "fields": {
            "breakfast": {
              "type": {
                "name": "object",
                "fields": {
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
              }
            },
            "dinner": {
              "type": {
                "name": "object",
                "fields": {
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
              }
            },
            "lunch": {
              "type": {
                "name": "object",
                "fields": {
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
              }
            },
            "other": {
              "type": {
                "name": "object",
                "fields": {
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
              }
            }
          }
        }
      },
      "name": {
        "type": {
          "name": "string"
        }
      },
      "saturday": {
        "type": {
          "name": "object",
          "fields": {
            "breakfast": {
              "type": {
                "name": "object",
                "fields": {
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
              }
            },
            "dinner": {
              "type": {
                "name": "object",
                "fields": {
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
              }
            },
            "lunch": {
              "type": {
                "name": "object",
                "fields": {
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
              }
            },
            "other": {
              "type": {
                "name": "object",
                "fields": {
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
              }
            }
          }
        }
      },
      "sunday": {
        "type": {
          "name": "object",
          "fields": {
            "breakfast": {
              "type": {
                "name": "object",
                "fields": {
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
              }
            },
            "dinner": {
              "type": {
                "name": "object",
                "fields": {
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
              }
            },
            "lunch": {
              "type": {
                "name": "object",
                "fields": {
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
              }
            },
            "other": {
              "type": {
                "name": "object",
                "fields": {
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
              }
            }
          }
        }
      },
      "thursday": {
        "type": {
          "name": "object",
          "fields": {
            "breakfast": {
              "type": {
                "name": "object",
                "fields": {
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
              }
            },
            "dinner": {
              "type": {
                "name": "object",
                "fields": {
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
              }
            },
            "lunch": {
              "type": {
                "name": "object",
                "fields": {
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
              }
            },
            "other": {
              "type": {
                "name": "object",
                "fields": {
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
              }
            }
          }
        }
      },
      "tuesday": {
        "type": {
          "name": "object",
          "fields": {
            "breakfast": {
              "type": {
                "name": "object",
                "fields": {
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
              }
            },
            "dinner": {
              "type": {
                "name": "object",
                "fields": {
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
              }
            },
            "lunch": {
              "type": {
                "name": "object",
                "fields": {
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
              }
            },
            "other": {
              "type": {
                "name": "object",
                "fields": {
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
              }
            }
          }
        }
      },
      "wednesday": {
        "type": {
          "name": "object",
          "fields": {
            "breakfast": {
              "type": {
                "name": "object",
                "fields": {
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
              }
            },
            "dinner": {
              "type": {
                "name": "object",
                "fields": {
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
              }
            },
            "lunch": {
              "type": {
                "name": "object",
                "fields": {
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
              }
            },
            "other": {
              "type": {
                "name": "object",
                "fields": {
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
              }
            }
          }
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


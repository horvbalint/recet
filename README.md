# Recet

## What is this?
Recet is an open source, work in progress recipe manager application built using Nuxt and SurrealDB. It is motivated from personal needs and the curiosity to see how much functionality can be squeezed out from using SurrealDB as the backend. My goal is to create a web app that feels great on both desktop and mobile using modern technologies like [PWA](https://web.dev/learn/pwa/progressive-web-apps/), [View Transition API](https://developer.mozilla.org/en-US/docs/Web/API/View_Transition_API), all while showcasing many features of SurrealDB.

## Functionality
I plan to create the following modules:
- Authentication ✅
- Households ✅
- Master data managment ✅
- Recipes ✅
- Shopping lists ✅
- Meal planner 👷
- Recipe import from (social) websites ❌
- Recipe AI ❌

## Polish
- Mobile ✅
- PWA ✅
- View Transitions ✅
- Dark Mode ✅

✅ - Working
👷‍♀️ - Work in progress
❌ - Coming later

## Screenshots
![A screenshot showing the recipes page](/public/screenshots/recipes-desktop.png?raw=true "The reipces page")

 | | |
 |---------|---------|
 | ![A screenshot showing the recipes page](/public/screenshots/recipes-mobile.png?raw=true "The reipces page") | ![A screenshot showing the recipes page](/public/screenshots/recipe-mobile.png?raw=true "The reipces page") |

## Is it ready?
No, well not yet. Besides some modules not being ready yet, SurrealDB currently does not provide every feature (email sending, plugins) that would be needed to make this app 'production ready' or better, something that can be shared with others. Household invites are currently automatically accepted and image compression is done client side.
Luckily SurrealDB v.3 is around the corner and these shortcommings are addressed in it.

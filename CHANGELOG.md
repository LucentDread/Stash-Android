# Changelog

## 1.13.0
- The app is available in English, French, German, Italian and Spanish,
  using the words of Stash's own translations. It follows the phone's
  language (English when the phone uses another one); More > Application >
  Settings > App language picks one instead. Open pages switch at once.
- Dates, sizes and counts follow the chosen language.
- The changelog, the release notes and the README are now written in
  English.

## 1.12.1
- Download a single image to view it offline: button in the viewer
  (More > Images, image views, galleries). Downloaded images have their own
  section in More > Downloads and can be swiped through together.

## 1.12.0
- Fix: on the default home, after scrolling to the bottom of the page, you
  could not get back to the top (the page scrolled down again by itself).
  Rows are no longer reloaded when scrolling back up.
- More > Home page: composition of both home pages.
  - Home: views and sections of the default home ("Continue watching",
    statistics, recently added…) stacked in the chosen order.
  - Default home: choice and order of its rows, views included (web filters
    too).

## 1.11.0
- More > Display > Tabs: choice and order of the bottom bar screens (up to
  4, plus "More") among Home, Scenes, Groups, Performers, Galleries, Images,
  Studios, Tags and Markers. The others stay in More.
- Scene page: studio logo as a watermark at the top right of the image, as
  on the cards.

## 1.10.2
- More > Images: every image of the library, with search and sort; a tap
  opens the viewer.
- Image views: new possible content for views (filters by performers, tags,
  studio, rating, resolution…). Image filters saved in the web UI are now
  included.
- Saved views: orange warning when a web filter contains criteria the app
  cannot apply (listed under the filter); they are ignored, so the view
  shows more items than on the web.

## 1.10.1
- Home with several views: each view has its own sort again (field and
  direction). The choice lasts until the app is closed; the saved view keeps
  its sort.

## 1.10.0
- Saved views of performers, studios, groups, galleries, tags or markers,
  besides scenes ("Content" choice), with the filters of each (favorites,
  rating, tags, studios…). The home page can thus stack a view of scenes
  then a view of studios or performers.
- Filters saved in the Stash web UI appear in More > Saved views (cloud
  icon): they open, go on the home page and are reordered with the app's
  views.
- Scene page: button to forget the video's resume position.

## 1.9.0
- Home: several saved views can make up the home page, stacked in the order
  of More > Saved views ("Show more" button per view). With a single view,
  the page takes its name.
- Popup player: the playing video continues in a small window when you
  leave the app, with a play/pause button.
- Black preview in recent apps.
- Optional password when the app opens, asked again after an adjustable
  time in the background.
- More > Application > Settings: popup player, privacy, password and
  updates.
- Updates: new versions published on GitHub are offered at startup, with
  their changes, then downloaded and installed from the app.

## 1.8.0
- Scraping: performers, tags, studios and groups missing from Stash can be
  created then linked from the comparison screen (checked by default), with
  the scraper's information (photo, dates, links…) and the link to the
  original stash-box.

## 1.7.1
- Fix: with random sort, cards came back twice after the next page loaded
  (and others never showed). Lists now use a fixed random seed per load,
  like the web client, and never show the same item twice.

## 1.7.0
- Scraping of performers, groups, galleries and studios, besides scenes
  (stash-box, server scrapers or URL, depending on what each supports).
- A scraper's search results are completed by a second call, as in the web
  client.

## 1.6.0
- Scene scraping from the edit screen, with a screen comparing the values.
- Offline downloads of scenes, groups and galleries (More > Downloads),
  played without the server.
- "Offline" window when the server cannot be reached, with direct access to
  the downloads; automatic reload when the connection comes back.

## 1.5.0
- More > Server: library scan, with progress at the bottom of every page
  (percentage, current file) and pages reloaded at the end.
- More > Application: app version.

## 1.4.0
- Star rating on the stats line of scene cards.
- Locked filter on the custom home; views editable in More > Saved views.
- Adding markers from the player; editing and deleting them.
- Editing images (cover, photo, logo, covers of groups) and galleries;
  cover taken from the frame being played.

## 1.3.0
- Editing scenes, performers, studios, tags and groups.
- Studio logo as a watermark on thumbnails.
- Header with the app's logo and name.

## 1.2.1
- Performer names removed from scene cards.
- Tab labels on a single line on small screens.

## 1.2.0
- More detailed cards (tags, plays, O counter) without empty space.

## 1.1.1
- Fixed tab labels and icons.

## 1.1.0
- Search by field (performers, tags, studio, groups, rating…).
- Saved views and custom home page.
- Groups tab.
- New icon and permanent APK signature.

## 1.0.0
- First version: home, scenes, performers, studios, tags, galleries,
  markers and video player.

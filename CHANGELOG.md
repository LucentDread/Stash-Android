# Changelog

## 1.19.8
- Android TV, on every page: Up/Down go to the next row, however short or
  narrow (from the right end of a home row, Down skipped a short row of
  groups for the favorite performers below it), then to its item closest
  horizontally. In the tabs' rail, Up/Down stay in the rail.
- Android TV, on every page: what cannot take the focus can be read.
  When nothing can take the focus further down (or up), or the next item
  is more than half a screen away, Up/Down scroll the page a step: a
  scene's information section, the home page's statistics (one more Up
  from the first row)…
- Launch: a dark screen with the app's logo instead of a white one that
  flashed before the app showed (on devices not in dark mode, as TVs
  usually are not; on Android 12+, the system's launch screen too).
- Android TV: the remote kept working wrongly once the focused item had
  scrolled out of sight (its position was unknown); it now goes on from
  what shows on screen.

## 1.19.7
- Android TV: pages scroll smoothly to the item getting the focus,
  instead of jumping, keeping room above it for its row's title; the
  first item of a page brings it back to its very top (the home page's
  statistics, which cannot take the focus, stayed hidden).
- Android TV, home page rows: Right at the end of a row stays there,
  instead of jumping to the row below.
- Android TV: where nothing lies in the pressed direction (e.g. Left from
  the tabs' rail), the focus stays, instead of landing on some other item
  (the first item of a row); the focus no longer goes "back to where it
  came from" by itself.
- Android TV, scene page: Up/Down go to the next row and its item closest
  horizontally (from the download button, Down could skip every row down
  to the last tag).
- Android TV: descriptions take the focus again (with a light background):
  Up/Down scroll through a long one step by step, then move on, so it can
  be read in full even with nothing focusable below it.

## 1.19.6
- Scene page on TVs and tablets in landscape:
  - the title bar shows as soon as the title has scrolled off the top,
    instead of once the whole header had (the title was lost meanwhile);
  - no more thin line of the picture at the edges of its fade (seen
    while pulling the page past its top, and as a faint vertical line);
    the blur no longer darkens the picture's edges.

## 1.19.5
- Scene page on TVs and tablets in landscape:
  - when its buttons (play, download, edit…) get the focus again, the
    page goes back to the top, picture whole, instead of stopping with
    the picture cut;
  - once scrolled past the top, a bar with the title stays at the top
    (with a back button on tablets), as on phones;
  - the picture slides slower than the page (parallax) and blurs more
    and more as the page goes down, up to a limit.
- Android TV: descriptions and file details are plain text, so the remote
  no longer stops in them line by line (they stay selectable on touch
  screens).

## 1.19.4
- Android TV, player: the remote's Back first hides the controls (or
  closes the ⋮ menu), then leaves the video. The back button on screen
  still leaves at once.

## 1.19.3
- Android TV: the focus shows in each item's own shape instead of a frame
  laid over the page: a white outline on buttons (round, pill-shaped…)
  and chips, a light background on list rows, tabs and the side rail, a
  white frame on pictures (cards, image tiles, markers). Text fields keep
  their own focused border.
- Android TV: Left/Right leave a text field once the cursor is at its
  start/end (e.g. from a search field to the tabs' rail).
- Android TV and tablets in landscape: a scene's page has a wide layout:
  its picture in the background of the top right, the title, details and
  buttons (play, download, edit) on the left, the rest below. On a TV,
  Play has the focus; on a tablet, a tap on the picture plays and a back
  button sits in the corner. Phones and tablets in portrait keep the
  current page.
- Android TV, player: the remote goes through the controls row by row (top
  bar, buttons, progress bar) and stops at the edges, instead of
  sometimes landing on nothing visible (the video, the page).

## 1.19.2
- Android TV: videos and image clips play. Every stream failed with
  "MediacodecVideoRenderer error": the TV's video decoders refuse to draw
  into the app's texture, so on a TV videos are drawn in an Android
  surface instead, as TV apps do. Phones are unchanged.
- Android TV: the play button over a scene's picture can be reached and
  pressed with the remote.
- Android TV, image viewer: Up/Down reach the buttons of the top bar
  (sound, download) and of the bottom bar (clip controls, rating); going
  past a bar's edge comes back to the picture, where Left/Right change
  images and OK shows or hides the bars.
- Android TV, player: the remote works as soon as the video opens (OK
  plays/pauses and goes to the buttons, Left/Right seek), instead of only
  once the controls had hidden themselves.
- A clip that cannot be played shows its thumbnail and the reason,
  instead of a broken picture.
- Android TV: a thick frame now shows what has the remote's focus, on
  every page and every kind of item (buttons, tabs, lists, fields…), and
  follows it while pages scroll.
- Android TV: items that do nothing (information rows, disabled buttons)
  no longer take the focus.
- Android TV: Up/Down leave a text field (from its first or last line for
  a multi-line one) and the player's and viewer's progress bars, instead
  of only Back, which also closed the page.

## 1.19.1
- One APK for every device: phones, tablets and Android TVs, 32- and
  64-bit (most TVs run a 32-bit system, which the 64-bit-only APK could
  not install on). Automatic updates now take this APK, from 1.18.x too.
- Releases get their signed APK built by GitHub Actions.

## 1.19.0
- Server unreachable: instead of errors, the home page (and any page that
  cannot load) says the server cannot be reached, with a button to the
  downloads and one to try again. The page comes back by itself once the
  server answers. The "Offline" popup now only shows when the connection
  is lost during use, not at launch.
- Android TV: the same APK installs on a TV and shows in its launcher
  (with a banner). With the remote: tabs in a rail on the left, the
  focused card framed, holding OK does a long press (scene preview,
  actions, selection); in the player, OK plays/pauses, Left/Right seek
  ±10 s, Up/Down show the controls, and the media keys work; in the image
  viewer, Left/Right change images.

## 1.18.3
- Animated GIFs open again in the image viewer (a red error icon showed
  since 1.16.2): Stash files them as videos, so the app took them for
  image clips the video player cannot play. They are pictures again, and
  a clip the player cannot open shows as a picture, which also fixes GIFs
  already downloaded.

## 1.18.2
- Image clips without a thumbnail: their preview frame is now taken once,
  natively and without a video player, and kept as a small picture. A
  tablet showing ~90 clips at once ran out of video decoders: previews
  stopped loading and the app could crash.
- Downloads: previews are decoded at the size of their tile.

## 1.18.1
- Image clips without a thumbnail: when Stash cannot make a clip's
  thumbnail it serves the whole clip instead, which the app loaded as a
  picture (no preview, and much memory, a likely cause of the crash when
  going back to the grid). The app now checks first and shows the first
  frame of the clip's preview video instead, like the web UI. Downloads
  keep no such false thumbnail.
- Big pictures are decoded at most at twice the screen width in the
  viewer, and previews at a small size, to spare the memory.
- Downloads: a small play badge in the corner of clips instead of the big
  icon over the preview.
- Downloads: select several items (long press, or the select button) to
  delete them at once; "All" selects the tab shown.

## 1.18.0
- At launch, the app checks the server (8 s at most): when it does not
  answer, the "Offline" popup with its Downloads button shows at once,
  instead of pages that never load. A proxy answering 5xx errors for a
  stopped Stash counts as unreachable too. Behind the lock screen, the
  popup comes once unlocked.
- Downloads page redesigned: one tab per kind (scenes, groups, galleries,
  images) with its count, and grids of cards with their preview, progress
  or failure over it. A tap opens; a long press (or a tap while it cannot
  open yet) offers to retry or delete.
- Downloaded images, image clips and galleries now have a preview: their
  Stash thumbnail is downloaded with them. Clips show a play icon.

## 1.17.1
- Image clips: buttons to go back or forward 10 seconds around a larger
  play/pause button, and a slider (easier to drag) to move through the
  clip.

## 1.17.0
- Image clips: a progress bar under the clip in the viewer, with
  play/pause, the position and the length; drag it to seek. It shows and
  hides with the other controls.
- Select several items to download them at once: a select button next to
  the sort in the lists of scenes, images, groups and galleries (tabs,
  More, saved views of those kinds, the scenes and galleries of a
  performer, studio, tag or group, the images of a gallery). Taps then
  select; "All" selects what is loaded; back leaves the selection.

## 1.16.2
- Image clips (video files that a library shows among the images) now play
  in the image viewer: looping, muted until the sound button is tapped.
  Their thumbnails carry a play icon, and downloaded clips play offline.

## 1.16.1
- Unrated items no longer show empty stars: nothing on cards, a "Not
  rated" button on pages and edit forms, which shows the stars to pick
  from (× goes back without rating).

## 1.16.0
- Ratings: a "×" button next to the stars clears the rating (tapping the
  current star still does too).
- Every item Stash can rate shows its rating and changes it with a tap:
  scenes, performers, studios and groups on their page, galleries in their
  information panel, images at the bottom of the viewer (not for offline
  copies). Tags and markers have no rating in Stash.

## 1.15.1
- Edit forms: when a searched performer, tag, studio or group does not
  exist, "Create “name”" adds it to Stash and selects it (e.g. a new tag
  straight from a scene's edit screen). Filters only offer existing items.

## 1.15.0
- Create performers, studios and tags too: "+" button at the top of their
  screens, like groups and galleries.
- Delete performers, studios, tags, groups and galleries: delete button in
  their edit screen, after a confirmation. The page closes and the lists
  reload. Galleries made of a folder or a zip file cannot be deleted (the
  next scan would bring them back); scenes and images, which are files,
  stay managed by the server.

## 1.14.0
- Create groups and galleries: "+" button at the top of the Groups and
  Galleries screens. The form is the edit one (name or title required);
  the new item opens once saved. A new gallery starts empty.

## 1.13.2
- Scene page: while scrolling, the scene title fades into the top bar at
  the pace it slides under it, and stays there further down. The other
  pages (performer, studio, group, gallery, tag) already show their name
  in the bar.

## 1.13.1
- Fix: the end of the scene page (links…) could sit under Android's
  navigation bar and not be tapped. Same fix for the other pages that
  scroll to the bottom: performer, studio, group and gallery pages, grids
  opened from More, saved views, filters, edit and scrape screens.

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

## 2.1.0

* Flutter minimum version `3.10.0`

# 2.0.2+1

* Fix Bug.

# 2.0.2

* Add speed adjustment.
* Solve the problem that the controller is visible and invisible.
* Increase the score.

# 2.0.1

* Fix Bug.
* Increase the score.

## 2.0.0

* Welcome to a brand-new version.
* Brings a lot of disruptive upgrades.
* Regarding the modification of the file name.
  * `VideoViewController` -> `VideoController`.
  * `VideoViewValue` -> `VideoValue`.
  * `VideoViewConfig` -> `VideoConfig`.
* Regarding the modification of the attribute name.
  * `tipBackgroundColor` -> `tooltipBackgroundColor`.
  * `defaultTextSize` -> `textSize`.
  * `defaultIconSize` -> `iconSize`.
  * `canUseSafe` -> `useSafe`.
  * `showCenterPlayButton` -> `showCenterPlay`.
  * `centerPlayButton` -> `centerPlayButtonBuilder`.
  * `topActions` -> `topActionsBuilder`.
  * `centerLeftActions` -> `centerLeftActionsBuilder`.
  * `centerRightActions` -> `centerRightActionsBuilder`.
  * `textPosition` -> `onTextPosition`.
  * `progressBarGap` -> `onProgressBarGap`.
* The attribute that was removed.
  * Delete `beforePlayBuilder`.
  * Delete `routePageBuilder`.
  * Delete `systemOverlaysEnterFullScreen`.
  * Delete `canShowDevice`.
* Newly added attributes.
  * Add `controlsType`.
  * Add `maxPreviewTime`.
  * Add `maxPreviewTimeBuilder`.

## 1.1.7

* Add `beforePlayBuilder`, `showCenterPlayButton`, `centerPlayButton`.
* Update `bufferingPlaceholder` to `bufferingBuilder`.

## 1.1.6+5

* Add `canBack` to control whether [BackButton] is displayed.

## 1.1.6+4

* Fixed issues after code detection.

## 1.1.6+3

* Modify the usage of `showControl`.
* Delete `showTopControl`.

## 1.1.6+2

* Horizontal and vertical screen transitions no longer use asynchronous methods.

## 1.1.6+1

* Fixed known problems.

## 1.1.6

* Add `showTopControl` to control the concealment of the top controller.
* Optimization.

## 1.1.5

* Optimize the initialization process.
* Add `showBuffering` to show placeholders in the buffer.
* Replace only the initial state modification. When `autoInitialize` or `autoPlay` is true, change the initialization status to loading.

## 1.1.4

### Retracted

* Replace only the initial state modification. When `autoInitialize` or `autoPlay` is true, change the initialization status to loading.

## 1.1.3

* Add `bottomBuilder` to customize your bottom control bar.
* Add `progressBarGap` to change the interval.

## 1.1.2

* No longer use the writing method of `VideoViewController.assets`, `VideoViewController.network`, `VideoViewController.file` and `VideoViewController.contentUri`.
* Update README.md.

## 1.1.1

* Adjust the safety zone of the controller.

## 1.1.0

### Breaking changes

* Use `VideoViewValue` instead of `VideoPlayerValue`, it will bring a better experience.
* For error handling, the state before the error is retained and restored to the original state after successful playback.

## 1.0.1

* Increase score.
* Fix example.

## 1.0.0

* Release the first edition.
* A view for video based on video_player and provides many basic functions.

## 0.0.1

* TODO: Describe initial release.

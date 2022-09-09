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

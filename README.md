[`embed_webview`](https://github.com/jixiaoyong/embed_webview) is a widget that display webview content inner flutter widget. It can change it's size automatically to fit the children.

By now, it support Android/iOS/Web.

## Getting started

Add `embed_webview` to your project.

```yaml
dependencies:
  flutter:
    sdk: flutter


  embed_webview:last_version
```

## Usage

Simply use it as other flutter widget:

```dart
const String SampleWebContent =
    """<p style="text-align: center;"><span style="color: rgb(41, 44, 50); font-size: 19px;">an&nbsp;open-source&nbsp;Embed&nbsp;Webview&nbsp;library.</span></p><p style="text-align: center;"><span style="color: rgb(41, 44, 50); font-size: 19px;">Made&nbsp;With&nbsp;❤️&nbsp;by&nbsp;JI,XIAOYONG.</span></p><p><br></p>""";

// somewhere need a widget:
return EmbedWebView(WebContent);
```

For more Infomation please checkout: [example](./example).


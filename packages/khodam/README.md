# Khodam <img src="https://raw.githubusercontent.com/hautvfami/khodam/main/media/logo.png" width="25px">

[![pub package](https://img.shields.io/pub/v/khodam.svg)](https://pub.dev/packages/khodam)
[![pub package](https://img.shields.io/github/license/hautvfami/khodam.svg?style=flat)](https://github.com/hautvfami/khodam)
[![pub package](https://img.shields.io/badge/platform-flutter-blue.svg)](https://github.com/hautvfami/khodam)

Khodam is an HTTP Inspector tool for Flutter which helps debugging http requests.
It catches and stores http requests and responses, which can be viewed via simple UI. 
It is inspired from Chuck (https://github.com/jgilfelt/chuck) and Chucker (https://github.com/ChuckerTeam/chucker).


Overlay bubble version of Khodam: https://github.com/jhomlala/khodam

<table>
  <tr>
    <td>
		<img width="250px" src="https://raw.githubusercontent.com/hautvfami/khodam/main/media/1.png">
    </td>
    <td>
       <img width="250px" src="https://raw.githubusercontent.com/hautvfami/khodam/main/media/2.png">
    </td>
    <td>
       <img width="250px" src="https://raw.githubusercontent.com/hautvfami/khodam/main/media/3.png">
    </td>
    <td>
       <img width="250px" src="https://raw.githubusercontent.com/hautvfami/khodam/main/media/4.png">
    </td>
     <td>
       <img width="250px" src="https://raw.githubusercontent.com/hautvfami/khodam/main/media/5.png">
    </td>
    <td>
       <img width="250px" src="https://raw.githubusercontent.com/hautvfami/khodam/main/media/6.png">
    </td>
  </tr>
  <tr>
    <td>
	<img width="250px" src="https://raw.githubusercontent.com/hautvfami/khodam/main/media/7.png">
    </td>
    <td>
       <img width="250px" src="https://raw.githubusercontent.com/hautvfami/khodam/main/media/8.png">
    </td>
    <td>
       <img width="250px" src="https://raw.githubusercontent.com/hautvfami/khodam/main/media/9.png">
    </td>
    <td>
       <img width="250px" src="https://raw.githubusercontent.com/hautvfami/khodam/main/media/10.png">
    </td>
    <td>
       <img width="250px" src="https://raw.githubusercontent.com/hautvfami/khodam/main/media/11.png">
    </td>
     <td>
       <img width="250px" src="https://raw.githubusercontent.com/hautvfami/khodam/main/media/12.png">
    </td>
  </tr>

</table>

**Supported Dart http client plugins:**

- Dio
- HttpClient from dart:io package
- Http from http/http package
- Chopper
- Generic HTTP client

**Features:**  
✔️ Detailed logs for each HTTP calls (HTTP Request, HTTP Response)  
✔️ Inspector UI for viewing HTTP calls  
✔️ Statistics  
✔️ Support for top used HTTP clients in Dart  
✔️ Error handling  
✔️ HTTP calls search
✔️ Bubble overlay entry

## Install

1. Add this to your **pubspec.yaml** file:

```yaml
dependencies:
  khodam: ^1.0.1
```

2. Install it

```bash
$ flutter pub get
```

3. Import it

```dart
import 'package:khodam/khodam.dart';
```

## Usage
### Khodam configuration
1. Create Khodam instance:

```dart
Khodam khodam = Khodam();
```

2. Add navigator key to your application:

```dart
MaterialApp( navigatorKey: khodam.getNavigatorKey(), home: ...)
```

You need to add this navigator key in order to show inspector UI.
You can use also your navigator key in Khodam:

```dart
Khodam khodam = Khodam(navigatorKey: yourNavigatorKeyHere);
```

If you need to pass navigatorKey lazily, you can use:
```dart
khodam.setNavigatorKey(yourNavigatorKeyHere);
```
This is minimal configuration required to run Khodam. Can set optional settings in Khodam constructor, which are presented below. If you don't want to change anything, you can move to Http clients configuration.

### Additional settings
If you want to use dark mode just add `darkTheme` flag:

```dart
Khodam khodam = Khodam(..., darkTheme: true);
```

### HTTP Client configuration
If you're using Dio, you just need to add interceptor.

```dart
Dio dio = Dio();
dio.interceptors.add(khodam.getDioInterceptor());
```


If you're using HttpClient from dart:io package:

```dart
httpClient
	.getUrl(Uri.parse("https://jsonplaceholder.typicode.com/posts"))
	.then((request) async {
		khodam.onHttpClientRequest(request);
		var httpResponse = await request.close();
		var responseBody = await httpResponse.transform(utf8.decoder).join();
		khodam.onHttpClientResponse(httpResponse, request, body: responseBody);
 });
```

If you're using http from http/http package:

```dart
http.get('https://jsonplaceholder.typicode.com/posts').then((response) {
    khodam.onHttpResponse(response);
});
```

If you're using Chopper. you need to add interceptor:

```dart
chopper = ChopperClient(
    interceptors: khodam.getChopperInterceptor(),
);
```

If you have other HTTP client you can use generic http call interface:
```dart
KhodamHttpCall khodamHttpCall = KhodamHttpCall(id);
khodam.addHttpCall(khodamHttpCall);
```

## Extensions
You can use extensions to shorten your http and http client code. This is optional, but may improve your codebase.
Example:
1. Import:
```dart
import 'package:khodam/core/khodam_http_client_extensions.dart';
import 'package:khodam/core/khodam_http_extensions.dart';
```

2. Use extensions:
```dart
http
    .post('https://jsonplaceholder.typicode.com/posts', body: body)
    .interceptWithKhodam(khodam, body: body);
```

```dart
httpClient
    .postUrl(Uri.parse("https://jsonplaceholder.typicode.com/posts"))
    .interceptWithKhodam(khodam, body: body, headers: Map());
```
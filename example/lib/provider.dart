import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

class Provider {

  static Future<List> resolveFembedUrl(String webUrl) async {
    http.Client client = http.Client();
    final String host = Uri.parse(webUrl).host;
    final String mediaId = List.from(webUrl.split('/').reversed)[0];
    final Map<String, String> headers = {
      'User-Agent': randUA(),
    };
    headers['Referer'] = webUrl;
    String apiUrl = 'https://$host/api/source/$mediaId';
    final res = await client.post(Uri.parse(apiUrl), headers: headers);
    if (res.statusCode == 200) {
      final Map<String, dynamic> apiRes = json.decode(res.body);
      if (apiRes['success']) {
        return apiRes['data'];
      }
    }
    return [];
  }

}
String randUA() {
  const uAS = [
    ieUserAgent,
    ffUserAgent,
    operaUserAgent,
    iosUserAgent,
    edgeUserAgent,
    chromeUserAgent,
    safariUserAgent,
    androidUserAgent
  ];
  return uAS[Random().nextInt(8)];
}


const ieUserAgent =
    'User-Agent: Mozilla/5.0 (Windows NT 10.0; WOW64; Trident/7.0; rv:11.0) like Gecko';
const ffUserAgent =
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:88.0) Gecko/20100101 Firefox/88.0';
const operaUserAgent =
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.132 Safari/537.36 OPR/67.0.3575.97';
const iosUserAgent =
    'Mozilla/5.0 (iPhone; CPU iPhone OS 13_3_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.5 Mobile/15E148 Safari/604.1';
const androidUserAgent =
    'Mozilla/5.0 (Linux; Android 9; SM-G973F) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/81.0.4044.138 Mobile Safari/537.36';
const edgeUserAgent =
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/70.0.3538.102 Safari/537.36 Edge/18.18363';
const chromeUserAgent =
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/84.0.4136.7 Safari/537.36';
const safariUserAgent =
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_4) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.1 Safari/605.1.15';


import "package:client/logic/auth.dart";
import "package:flutter_test/flutter_test.dart";
import "package:http/http.dart" as http;
import "package:http/testing.dart";

void main() {
  group("Auth.login", () {
    test("returns successfully on 201", () async {
      final mockClient = MockClient((request) async {
        expect(request.url.toString(), "https://example.com/auth");
        expect(request.headers["Authorization"], "valid-token");
        return http.Response("", 201);
      });

      final auth = Auth(client: mockClient, baseUrl: "https://example.com");

      await expectLater(auth.login("valid-token"), completes);
    });

    test("throws AuthException('Invalid token') on 401", () async {
      final mockClient = MockClient((request) async => http.Response("", 401));

      final auth = Auth(client: mockClient, baseUrl: "https://example.com");

      expect(
        () => auth.login("bad-token"),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            "message",
            "Invalid token",
          ),
        ),
      );
    });

    test("throws AuthException('Unknown error') on non-201/401", () async {
      final mockClient = MockClient((request) async => http.Response("", 500));

      final auth = Auth(client: mockClient, baseUrl: "https://example.com");

      expect(
        () => auth.login("any-token"),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            "message",
            "Unknown error",
          ),
        ),
      );
    });
  });
}

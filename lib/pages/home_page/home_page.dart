import 'dart:developer';

import 'package:commuter/pods/location.dart';
import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class HomePage extends ConsumerWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = gql("""
      query(\$near: [Float!]!) {
        userStopPoints(first: 100, near: \$near) {
          pageInfo {
            hasNextPage
            endCursor
          }
          nodes {
            userStopCode
            name
            town
            stopArea {
              userStopAreaCode
              name
            }
            lines {
              nodes {
                linePublicNumber
                lineColor
                lineTextColor
              }
            }
          }
        }
      }
    """);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Commuter'),
      ),
      body: ref.watch(locationProvider).map(
            data: (pos) {
              inspect(pos);
              return Query(
                options: QueryOptions(
                  document: query,
                  variables: {
                    "near": [pos.value.latitude, pos.value.longitude],
                  },
                ),
                builder: _buildList,
              );
            },
            error: (e) => Center(
              child: Text(e.toString()),
            ),
            loading: (e) {
              inspect(e);
              return Center(
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: Stack(
                    children: const [
                      CircularProgressIndicator(),
                      Center(child: Icon(Icons.location_on)),
                    ],
                  ),
                ),
              );
            },
          ),
    );
  }

  Widget _buildList(QueryResult result, {fetchMore, refetch}) {
    if (result.hasException) {
      log("", error: result.exception);
      return Center(
        child: Text(result.exception.toString()),
      );
    }

    if (result.data == null && result.isNotLoading) {
      return const Center(
        child: Text("No data"),
      );
    }

    if (result.data == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final stopIdx = <String, List<dynamic>>{};

    for (final node
        in result.data!["userStopPoints"]["nodes"] as List<dynamic>) {
      final key = node["stopArea"]?["name"] ?? node["name"];

      if (stopIdx[key] == null) {
        stopIdx[key] = [];
      }

      node["name"] = key;

      stopIdx[key]!.add(node);
    }

    final stops = stopIdx.values.toList();

    return Scrollbar(
      interactive: true,
      child: ListView.builder(
        itemCount: stops.length,
        itemBuilder: (context, index) {
          final stopName = stops[index][0]["name"];
          final lines = stops[index]
              .expand((n) => n["lines"]["nodes"])
              .map((v) => _Line.fromGraphQL(v))
              .toSet()
              .toList();

          lines.sort();

          return ListTile(
            leading: Icon(Icons.directions_bus),
            title: Text(stopName),
            subtitle: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                ...lines.map<Widget>(
                  (line) => _LineDisplay(line),
                ),
              ],
            ),
            onTap: () {
              final ids =
                  stops[index].map((e) => e["userStopCode"]).toList().join(".");

              context.push("/stop-area/$ids", extra: {
                "name": stopName,
              });
            },
          );
        },
      ),
    );
  }
}

class _Line implements Comparable {
  final String number;
  final Color? color;

  final Color? _textColor;
  Color? get textColor {
    if (_textColor != null) {
      return _textColor!;
    }

    if (color != null) {
      return color!.computeLuminance() > 0.5 ? Colors.black : Colors.white;
    }

    return null;
  }

  const _Line({
    required this.number,
    this.color,
    textColor,
  }) : _textColor = textColor;

  factory _Line.fromGraphQL(Map<String, dynamic> line) {
    return _Line(
      number: line['linePublicNumber'],
      color: line['lineColor'] != null
          ? Color(int.parse(line['lineColor'], radix: 16)).withOpacity(1)
          : null,
      textColor: line['lineTextColor'] != null
          ? Color(int.parse(line['lineTextColor'], radix: 16)).withOpacity(1)
          : null,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is _Line &&
        other.number == number &&
        other.color == color &&
        other.textColor == textColor;
  }

  @override
  int get hashCode => number.hashCode ^ color.hashCode ^ textColor.hashCode;

  @override
  String toString() =>
      'Line(number: $number, color: $color, textColor: $textColor)';

  @override
  int compareTo(dynamic other) {
    if (other is _Line) {
      try {
        return int.parse(number).compareTo(int.parse(other.number));
      } catch (e) {
        return number.compareTo(other.number);
      }
    }

    return 0;
  }
}

class _LineDisplay extends StatelessWidget {
  final _Line line;

  const _LineDisplay(
    this.line, {
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: line.color,
        borderRadius: BorderRadius.circular(8),
      ),
      // minimum width
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: 24,
        ),
        child: Text(
          line.number,
          style: TextStyle(
            color: line.textColor,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

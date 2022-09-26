import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class StopAreaPage extends ConsumerWidget {
  final List<String> ids;
  final String? name;

  const StopAreaPage({
    Key? key,
    required this.ids,
    this.name,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(name ?? ids.join(", ")),
      ),
      body: _buildQuery(),
    );
  }

  Query _buildQuery() {
    final opts = QueryOptions(
      document: gql(
        """
            query(\$ids: [String!]!) {
              userStopPoints(ids: \$ids) {
                nodes {
                  name
                  lat
                  long
                }
              }
            }
          """,
      ),
      variables: {
        "ids": ids,
      },
    );

    return Query(
      options: opts,
      builder: (result, {fetchMore, refetch}) {
        if (result.hasException) {
          return Center(
            child: Text(result.exception.toString()),
          );
        }

        if (result.data == null) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        return _buildGoogleMap(result);
      },
    );
  }

  GoogleMap _buildGoogleMap(
    QueryResult<Object?> result,
  ) {
    final lat = (result.data!["userStopPoints"]["nodes"] as List<dynamic>)
            .map<double>(
              (e) => e["lat"],
            )
            .reduce((value, element) => value + element) /
        result.data!["userStopPoints"]["nodes"].length;

    final long = (result.data!["userStopPoints"]["nodes"] as List<dynamic>)
            .map<double>(
              (e) => e["long"],
            )
            .reduce((value, element) => value + element) /
        result.data!["userStopPoints"]["nodes"].length;

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: LatLng(lat, long),
        zoom: 17,
      ),
      markers: {
        for (final node in result.data!["userStopPoints"]["nodes"])
          Marker(
            markerId: MarkerId(node["name"]),
            position: LatLng(node["lat"], node["long"]),
          ),
      },
    );
  }
}

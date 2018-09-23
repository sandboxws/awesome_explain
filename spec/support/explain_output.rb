PRODUCT_COLLSCAN = <<-EOF
{
  "queryPlanner"   => {
    "plannerVersion" => 1,
    "namespace"      => "awesome_explain.products",
    "indexFilterSet" => false,
    "parsedQuery"    => {
      "name" => {
        "$eq" => "Coffee Beans - Chocolate"
      }
    },
    "winningPlan"    => {
      "stage"     => "COLLSCAN",
      "filter"    => {
        "name" => {
          "$eq" => "Coffee Beans - Chocolate"
        }
      },
      "direction" => "forward"
    },
    "rejectedPlans"  => []
  },
  "executionStats" => {
    "executionSuccess"    => true,
    "nReturned"           => 0,
    "executionTimeMillis" => 2,
    "totalKeysExamined"   => 0,
    "totalDocsExamined"   => 1000,
    "executionStages"     => {
      "stage"                       => "COLLSCAN",
      "filter"                      => {
        "name" => {
          "$eq" => "Coffee Beans - Chocolate"
        }
      },
      "nReturned"                   => 0,
      "executionTimeMillisEstimate" => 0,
      "works"                       => 1002,
      "advanced"                    => 0,
      "needTime"                    => 1001,
      "needYield"                   => 0,
      "saveState"                   => 7,
      "restoreState"                => 7,
      "isEOF"                       => 1,
      "invalidates"                 => 0,
      "direction"                   => "forward",
      "docsExamined"                => 1000
    },
    "allPlansExecution"   => []
  },
  "serverInfo"     => {
    "host"       => "Ahmeds-MacBook-Pro.local",
    "port"       => 27017,
    "version"    => "3.4.10",
    "gitVersion" => "078f28920cb24de0dd479b5ea6c66c644f6326e9"
  },
  "ok"             => 1.0
}
EOF

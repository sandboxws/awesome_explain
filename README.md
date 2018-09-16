# AwesomeExplain

Awesome explain is a simple global method that provides quick insights into mongodb's query plan and execution stats.
Currently the explain functionality only supports `Mongo::Collection::View::Aggregation` & ``Mongoid::Criteria`.

[![Build Status](https://travis-ci.com/sandboxws/awesome_explain.svg?branch=master)](https://travis-ci.com/sandboxws/awesome_explain)
[![Maintainability](https://api.codeclimate.com/v1/badges/75e1a5cb4b6a5c1ba4c8/maintainability)](https://codeclimate.com/github/sandboxws/awesome_explain/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/75e1a5cb4b6a5c1ba4c8/test_coverage)](https://codeclimate.com/github/sandboxws/awesome_explain/test_coverage)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Installation

Add the following line to your application's Gemfile:

`gem 'awesome_explain', require: true`

## Usage

`ae Article.where(author_id: '5b9ec484d5cc2e697189d7c9')`

```
+--------------------+-----------------------------+
| Winning Plan       | FETCH (7 / 7) -> IXSCAN (7) |
+--------------------+-----------------------------+
| Used Indexes       | author_id_1 (forward)       |
+--------------------+-----------------------------+
| Rejected Plans     | 0                           |
+--------------------+-----------------------------+
| Documents Returned | 7                           |
+--------------------+-----------------------------+
| Documents Examined | 7                           |
+--------------------+-----------------------------+
| Keys Examined      | 7                           |
+--------------------+-----------------------------+
| Execution time(ms) | 0                           |
+--------------------+-----------------------------+
| Execution time(s)  | 0.0                         |
+--------------------+-----------------------------+
```

`ae Article.or([{author_id: '5b9ec484d5cc2e697189d7c9', state: 'published'}, {created_at: 3.days.ago}])`

```

+--------------------+-------------------------------------------------------------------------------------------------------------------------------------------+
| Winning Plan       | SORT (20) -> SORT_KEY_GENERATOR (20) -> FETCH (24 / 20) -> OR (24) -> [  FETCH (24 / 24) -> IXSCAN (24) ,  FETCH (0 / 0) -> IXSCAN (0) ]  |
+--------------------+-------------------------------------------------------------------------------------------------------------------------------------------+
| Used Indexes       | state_1 (forward), author_id_1 (forward)                                                                                                  |
+--------------------+-------------------------------------------------------------------------------------------------------------------------------------------+
| Rejected Plans     | 18                                                                                                                                        |
+--------------------+-------------------------------------------------------------------------------------------------------------------------------------------+
| Documents Returned | 20                                                                                                                                        |
+--------------------+-------------------------------------------------------------------------------------------------------------------------------------------+
| Documents Examined | 48                                                                                                                                        |
+--------------------+-------------------------------------------------------------------------------------------------------------------------------------------+
| Keys Examined      | 24                                                                                                                                        |
+--------------------+-------------------------------------------------------------------------------------------------------------------------------------------+
| Execution time(ms) | 37                                                                                                                                        |
+--------------------+-------------------------------------------------------------------------------------------------------------------------------------------+
| Execution time(s)  | 0.037                                                                                                                                     |
+--------------------+-------------------------------------------------------------------------------------------------------------------------------------------+
```

## Winning Plan Examples

`FETCH (7 / 7) -> IXSCAN (7)`

Below is a breakdown of the above winning plan:

- First stage is a `FETCH` stage. 7 documents were examined, and 7 were returned.
- Second stage was an `IXSCAN` stage were 7 documents were returned.

For information about MongoDB's explain output, please refer to the official MongoDB Explain documentation:
https://docs.mongodb.com/manual/reference/explain-results/

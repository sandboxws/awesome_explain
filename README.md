# AwesomeExplain

AwesomeExplain provides the same APM's level of query analysis under your development and test Rails environments.

## Main Features

* A set of utilities for analyzing MongoDB and SQL queries from Rails console.
* Tracking queries under your database of choice (SQLite3 or PostgreSQL)
which can be viewed under [Athena's](https://github.com/sandboxws/athena_dashboard) dashboard.

![Build Status](https://github.com/sandboxws/awesome_explain/actions/workflows/mongodb.yml/badge.svg)
![Build Status](https://github.com/sandboxws/awesome_explain/actions/workflows/postgres.yml/badge.svg)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Installation

Add the following line to your application's Gemfile:

`gem 'awesome_explain', require: true`

## Console Utility Methods

* **ae**: Prints a query's execution plan using a user friendly terminal table
  * Currently supports the following classes:
    * `Mongo::Collection::View::Aggregation`
    * `Mongoid::Criteria`
    * `ActiveRecord::Relation`
* **analyze**: Prints a summary of all MongoDB queries passed to the Ruby block
* **analyze_ar**: Prints a summary of all ActiveRecord queries passed to the Ruby block

*Detailed usage examples can be found below.*

## MongoDB

### Usage

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

`ae Product.where(_id: 22)`

```
+--------------------+----------------+
| Winning Plan       | IDHACK (1 / 1) |
+--------------------+----------------+
| Used Indexes       |                |
+--------------------+----------------+
| Rejected Plans     | 0              |
+--------------------+----------------+
| Documents Returned | 1              |
+--------------------+----------------+
| Documents Examined | 1              |
+--------------------+----------------+
| Keys Examined      | 1              |
+--------------------+----------------+
| Execution time(ms) | 90             |
+--------------------+----------------+
| Execution time(s)  | 0.09           |
+--------------------+----------------+
```

### Winning Plan Examples

`FETCH (7 / 7) -> IXSCAN (7)`

Below is a breakdown of the above winning plan:

- First stage is a `FETCH` stage. 7 documents were examined, and 7 were returned.
- Second stage was an `IXSCAN` stage were 7 documents were returned.

For information about MongoDB's explain output, please refer to the official MongoDB Explain documentation:
https://docs.mongodb.com/manual/reference/explain-results/

## PostgreSQL

### ae Usage

#### Query using PK index

`ae Film.where(film_id: 1)`

```
+--------------------+-------+
|       General Stats        |
+--------------------+-------+
| Table              | Count |
+--------------------+-------+
| Total Rows Planned | 1     |
| Total Rows         | 1     |
| Total Loops        | 1     |
| Seq Scans          | 0     |
| Indexes Used       | 1     |
+--------------------+-------+
|        Table Stats         |
+--------------------+-------+
| Table              | Count |
+--------------------+-------+
| film               | 1     |
+--------------------+-------+
|      Node Type Stats       |
+--------------------+-------+
| Node Type          | Count |
+--------------------+-------+
| Index Scan         | 1     |
+--------------------+-------+
|        Index Stats         |
+--------------------+-------+
| Index Name         | Count |
+--------------------+-------+
| film_pkey          | 1     |
+--------------------+-------+
```

#### Query not using any index

`ae Film.where(description: 'Alien Center')`

```
+--------------------+-------+
|       General Stats        |
+--------------------+-------+
| Table              | Count |
+--------------------+-------+
| Total Rows Planned | 1     |
| Total Rows         | 0     |
| Total Loops        | 1     |
| Seq Scans          | 1     |
| Indexes Used       | 0     |
+--------------------+-------+
|        Table Stats         |
+--------------------+-------+
| Table              | Count |
+--------------------+-------+
| film               | 1     |
+--------------------+-------+
|      Node Type Stats       |
+--------------------+-------+
| Node Type          | Count |
+--------------------+-------+
| Seq Scan           | 1     |
+--------------------+-------+
```

### analyze_ar Usage

`analyze_ar { Film.where(film_id: 1).to_a; Actor.where(last_name: 'Cage').to_a };0`

```
+--------------------+----------------+
| Time (sec)         | 0.0            |
+--------------------+----------------+
| Total Rows Planned | 3              |
+--------------------+----------------+
| Total Rows         | 3              |
+--------------------+----------------+
| Total Loops        | 2              |
+--------------------+----------------+
| Seq Scans          | 1              |
+--------------------+----------------+
| Tables             | film (1)       |
|                    | actor (1)      |
+--------------------+----------------+
| Node Types         | Index Scan (1) |
|                    | Seq Scan (1)   |
+--------------------+----------------+
| Indexes            | film_pkey (1)  |
+--------------------+----------------+
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/sandboxws/awesome_explain. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the AwesomeExplain project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/sandboxws/awesome_explain/blob/master/CODE_OF_CONDUCT.md).

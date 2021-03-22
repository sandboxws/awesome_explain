# AwesomeExplain

Awesome explain is a simple global method that provides quick insights into mongodb's query plan and execution stats.
Currently the explain functionality only supports `Mongo::Collection::View::Aggregation` & `Mongoid::Criteria`.

![Build Status](https://github.com/sandboxws/awesome_explain/actions/workflows/ruby.yml/badge.svg)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

<a href="https://www.universe.com/" target="_blank" rel="noopener noreferrer">
  <img src="images/universe.png" height="41" width="153" alt="Sponsored by Universe" style="max-width:100%;">
</a>

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

## Winning Plan Examples

`FETCH (7 / 7) -> IXSCAN (7)`

Below is a breakdown of the above winning plan:

- First stage is a `FETCH` stage. 7 documents were examined, and 7 were returned.
- Second stage was an `IXSCAN` stage were 7 documents were returned.

For information about MongoDB's explain output, please refer to the official MongoDB Explain documentation:
https://docs.mongodb.com/manual/reference/explain-results/

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/sandboxws/awesome_explain. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the AwesomeExplain project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/sandboxws/awesome_explain/blob/master/CODE_OF_CONDUCT.md).

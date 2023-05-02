## Installation

First clone this repository to your laptop:

```bash
cd ~/code
git clone git@github.com:RobertoBarros/rspec_explain_formatter.git
```

## Running Specs:

```bash
rspec --require ~/code/rspec_explain_formatter/explain_formatter.rb --format ExplainFormatter
```

To execute only a group of spect use the `-t` option, like:

```bash
rspec -t meal --require ~/code/rspec_explain_formatter/explain_formatter.rb --format ExplainFormatter
```

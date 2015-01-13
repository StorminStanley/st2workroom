# stacks

WTF is a stack?!

Vagrant is a prototyping environment. However, I go back to the lego analogy. I want infrastructure as code all the way down.

You can dynamically build vagrant environments based on a stack. Take a look at template.yaml to see what's going on.

To use a stack, set the env variable `stack`.

```
export stack=cicd
vagrant status
```

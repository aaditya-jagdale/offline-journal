---
trigger: always_on
---

### These are flutter app rules that you must follow at all times

##1. Folder structure
You must follow feature first folder structure where we are creating folders as per features.

lib/
  |
  |_ home/
        |
        |_ models/
        |_ screens/
        |_ widgets/

and this will be horizontally scalable isolating each function in its on directory


##2. Riverpod style
We are going to stick with riverpod state management forever. For building up models we are ONLY going to use freezed data models: eg

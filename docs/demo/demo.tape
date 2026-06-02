# ccpick 데모 GIF. 저장소 루트에서 실행: vhs docs/demo/demo.tape
# 녹화는 /tmp/ccpick-demo 샌드박스(가짜 plans.env + 가짜 claude)에서 이뤄진다.
Output docs/demo.gif

Set Shell bash
Set FontSize 20
Set Width 800
Set Height 480
Set Padding 16
Set BorderRadius 8
Set WindowBar Colorful
Set Theme "Catppuccin Mocha"
Set TypingSpeed 60ms

Hide
Type "bash docs/demo/setup.sh && export CCPICK_PLANS=/tmp/ccpick-demo/plans.env CLAUDE_CONFIG_DIR=/tmp/ccpick-demo PATH=/tmp/ccpick-demo/bin:$PWD/bin:$PATH && clear"
Enter
Sleep 1s
Show

Type "ccpick"
Sleep 500ms
Enter
Sleep 1.5s

Down
Sleep 1s
Enter
Sleep 2s

Type "! echo $CCPICK_PLAN"
Sleep 500ms
Enter
Sleep 3s

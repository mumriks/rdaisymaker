<?xml version='1.0' encoding='UTF-8'?>
<!DOCTYPE resources PUBLIC "-//NISO//DTD resource 2005-1//EN" "resource-2005-1.dtd">
<resources xmlns="http://www.daisy.org/z3986/2005/resource/" version="2005-1">

  <!-- SKIPPABLE NCX -->
  <scope nsuri="http://www.daisy.org/z3986/2005/ncx/">
    <nodeSet id="ns001" select="//smilCustomTest[@bookStruct='LINE_NUMBER']">
      <resource xml:lang="ja" id="r001">
        <text>ライン番号</text>
      </resource>
    </nodeSet>

    <nodeSet id="ns002" select="//smilCustomTest[@bookStruct='NOTE']">
      <resource xml:lang="ja" id="r002">
        <text>ノート</text>
      </resource>
    </nodeSet>

    <nodeSet id="ns003" select="//smilCustomTest[@bookStruct='NOTE_REFERENCE']">
      <resource xml:lang="ja" id="r003">
        <text>ノートリファレンス</text>
      </resource>
    </nodeSet>

    <nodeSet id="ns004" select="//smilCustomTest[@bookStruct='ANNOTATION']">
      <resource xml:lang="ja" id="r004">
        <text>アノテーション</text>
      </resource>
    </nodeSet>

    <nodeSet id="ns005" select="//smilCustomTest[@bookStruct='PAGE_NUMBER']">
      <resource xml:lang="ja" id="r005">
        <text>ページ</text>
      </resource>
    </nodeSet>

    <nodeSet id="ns006" select="//smilCustomTest[@bookStruct='OPTIONAL_SIDEBAR']">
      <resource xml:lang="ja" id="r006">
        <text>サイドバー</text>
      </resource>
    </nodeSet>

    <nodeSet id="ns007" select="//smilCustomTest[@bookStruct='OPTIONAL_PRODUCER_NOTE']">
      <resource xml:lang="ja" id="r007">
        <text>プロデューサーノート</text>
      </resource>
    </nodeSet>
  </scope>

  <!-- ESCAPABLE SMIL -->
  <scope nsuri="http://www.w3.org/2001/SMIL20/">
    <nodeSet id="sm001" select="//seq[@class='table']">
      <resource xml:lang="ja" id="smr001">
        <text>テーブル</text>
      </resource>
    </nodeSet>
  </scope>

  <!-- ESCAPABLE DTBOOK -->
  <scope nsuri="http://www.daisy.org/z3986/2005/dtbook/">
    <nodeSet id="dt001" select="//table">
      <resource xml:lang="ja" id="dtr001">
        <text>テーブル</text>
      </resource>
    </nodeSet>
  </scope>

</resources>
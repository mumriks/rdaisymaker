# encoding: utf-8
# 文字列のひらがな・カタカナ変換
# 2010/09/13 kishi24
$KCODE = "UTF-8" if RUBY_VERSION < '1.9'

class ExchangeKana < String
  KANA_TBL = [["あ","ア"],["い","イ"],["う","ウ"],["え","エ"],["お","オ"],["か","カ"],["き","キ"],["く","ク"],["け","ケ"],["こ","コ"],["さ","サ"],["し","シ"],["す","ス"],["せ","セ"],["そ","ソ"],["た","タ"],["ち","チ"],["つ","ツ"],["て","テ"],["と","ト"],["な","ナ"],["に","ニ"],["ぬ","ヌ"],["ね","ネ"],["の","ノ"],["は","ハ"],["ひ","ヒ"],["ふ","フ"],["へ","ヘ"],["ほ","ホ"],["ま","マ"],["み","ミ"],["む","ム"],["め","メ"],["も","モ"],["や","ヤ"],["ゆ","ユ"],["よ","ヨ"],["ら","ラ"],["り","リ"],["る","ル"],["れ","レ"],["ろ","ロ"],["わ","ワ"],["を","ヲ"],["ん","ン"],["ぁ","ァ"],["ぃ","ィ"],["ぅ","ゥ"],["ぇ","ェ"],["ぉ","ォ"],["ゃ","ャ"],["ゅ","ュ"],["ょ","ョ"],["ゎ","ヮ"],["っ","ッ"],["ヵ","ヵ"],["ヶ","ヶ"],["ー","ー"],["が","ガ"],["ぎ","ギ"],["ぐ","グ"],["げ","ゲ"],["ご","ゴ"],["ざ","ザ"],["じ","ジ"],["ず","ズ"],["ぜ","ゼ"],["ぞ","ゾ"],["だ","ダ"],["ぢ","ヂ"],["づ","ヅ"],["で","デ"],["ど","ド"],["ば","バ"],["び","ビ"],["ぶ","ブ"],["べ","ベ"],["ぼ","ボ"],["ヴ","ヴ"],["ぱ","パ"],["ぴ","ピ"],["ぷ","プ"],["ぺ","ペ"],["ぽ","ポ"]]

  def initialize (str)
    @str = str
  end

  def exchange_kana_at (hash_tbl)
    exchange_str = ''
    @str.scan(/./) do |s|
      if hash_tbl.include?(s)
        exchange_str << hash_tbl[s]
      else
        exchange_str << s
      end
    end
    exchange_str
  end

  def to_katakana
    hiragana2katakana_hash = Hash.new
    KANA_TBL.each do |hiragana, katakana|
      hiragana2katakana_hash.store hiragana, katakana
    end
    exchange_kana_at hiragana2katakana_hash
  end

  def to_hiragana
    katakana2hiragana_hash = Hash.new
    KANA_TBL.each do |hiragana, katakana|
      katakana2hiragana_hash.store katakana, hiragana
    end
    exchange_kana_at katakana2hiragana_hash
  end

end

__END__

hiragana_str = "あかさたなはまやらわんぁゃゎAb="
hiragana = ExchangeKana.new(hiragana_str)
p hiragana_str
p hiragana.to_katakana

katakana_str = "アカサタナハマヤラワンァャヮxyZ;:"
katakana = ExchangeKana.new(katakana_str)
p katakana_str
p katakana.to_hiragana


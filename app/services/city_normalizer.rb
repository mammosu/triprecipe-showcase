module CityNormalizer
  FULLWIDTH = "ＡＢＣＤＥＦＧＨＩＪＫＬＭＮＯＰＱＲＳＴＵＶＷＸＹＺａｂｃｄｅｆｇｈｉｊｋｌｍｎｏｐｑｒｓｔｕｖｗｘｙｚ０１２３４５６７８９".freeze
  HALFWIDTH = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789".freeze

  IRRELEVANT_PAREN = /[()（）\[\]{}]/.freeze
  IRRELEVANT_SEPARATORS = /[\-・,、.]/.freeze
  WHITESPACE = /[\s\u00A0]+/.freeze

  module_function

  def normalize(str)
    return nil if str.blank?

    normalized = str.to_s.tr(FULLWIDTH, HALFWIDTH)
    normalized = normalized.gsub(WHITESPACE, "")
    normalized = normalized.gsub(IRRELEVANT_PAREN, "")
    normalized = normalized.gsub(IRRELEVANT_SEPARATORS, "")
    normalized.downcase
  end
end

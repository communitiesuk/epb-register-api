module UseCase
  module PostcodeData
    def self.wales_only_prefixes
      %w[CF SA LL3 LL4 LL5 LL6 LL7]
    end

    def self.wales_only_outcodes
      %w[CH5
         CH6
         CH7
         CH8
         LD1
         LD2
         LD3
         LD4
         LD5
         LD6
         LL15
         LL16
         LL17
         LL18
         LL19
         LL21
         LL22
         LL23
         LL24
         LL25
         LL26
         LL27
         LL28
         LL29
         NP4
         NP8
         NP10
         NP11
         NP12
         NP13
         NP15
         NP18
         NP19
         NP20
         NP22
         NP23
         NP24
         NP26
         NP44
         SY16
         SY17
         SY18
         SY19
         SY20
         SY22
         SY23
         SY24
         SY25]
    end

    def self.cross_border_eaw_outcodes
      %w[CH1
         CH4
         HR2
         HR3
         HR5
         LD7
         LD8
         LL11
         LL12
         LL13
         LL14
         LL20
         NP7
         NP16
         NP25
         SY5
         SY10
         SY15
         SY21]
    end

    def self.in_wales_only
      Regexp.new((wales_only_prefixes.map { |fragment| "^#{fragment}" } + wales_only_outcodes.map { |fragment| "(#{fragment}\s)" }).join("|"))
    end

    def self.cross_border_eaw_regex
      Regexp.new("^#{cross_border_eaw_outcodes.map { |fragment| "(#{fragment}\s)" }.join('|')}")
    end

    def self.cross_border_england_and_scotland_outcodes
      %w[DG16 TD9 TD12 TD15]
    end

    def self.scotland_only_prefixes
      %w[AB DD EH FK G HS IV KA KW KY ML PA PH ZE]
    end

    def self.scotland_only_outcodes
      %w[DG1 DG2 DG3 DG4 DG5 DG6 DG7 DG8 DG9 DG10 DG11 DG12 DG13 DG14 TD1 TD2 TD3 TD4 TD5 TD6 TD7 TD8 TD10 TD11 TD13 TD14]
    end

    def self.in_scotland_only_regex
      Regexp.new((scotland_only_prefixes.map { |fragment| "(^#{fragment}\\d)" } + scotland_only_outcodes.map { |fragment| "(#{fragment}\s)" }).join("|"))
    end

    def self.cross_border_england_and_scotland_regex
      Regexp.new("^#{cross_border_england_and_scotland_outcodes.map { |fragment| "(#{fragment}\s)" }.join('|')}")
    end
  end
end

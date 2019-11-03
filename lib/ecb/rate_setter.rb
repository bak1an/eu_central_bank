module ECB
  class RateSetter
    attr_reader :store

    LEGACY_CURRENCIES = %w(CYP SIT ROL TRL)

    def initialize(rates_document = nil, type = nil)
      @rates_document = rates_document
      @type = type
    end

    def update_rates(store)
      store.transaction true do
        copy_rates(@rates_document, store) if @type == :current
        copy_rates(@rates_document, store, true) if @type == :historical
      end
      [@rates_document.updated_at, Time.now]
    end

    def set_rate(store, from, to, rate, date = nil)
      # Backwards compatibility for the opts hash
      date = date[:date] if date.is_a?(Hash)
      store.add_rate(::Money::Currency.wrap(from).iso_code, ::Money::Currency.wrap(to).iso_code, rate, date)
    end

    private

    def copy_rates(rates_document, store, with_date = false)
      rates_document.rates.each do |date, rates|
        rates.each do |currency, rate|
          next if LEGACY_CURRENCIES.include?(currency)
          set_rate(store, 'EUR', currency, BigDecimal(rate), with_date ? date : nil)
        end
        set_rate(store, 'EUR', 'EUR', 1, with_date ? date : nil)
      end
    end
  end

  class CurrentRateSetter < RateSetter
    def initialize(rates_document)
      super(rates_document, :current)
    end
  end

  class HistoricalRateSetter < RateSetter
    def initialize(rates_document)
      super(rates_document, :historical)
    end
  end
end

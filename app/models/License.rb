require 'csv'

class License 
  @@commercial_purchase =
    {'Evaluation' => 0, '10 Users' => 10, '25 Users' => 10, '50 Users' => 50, '100 Users' => 50,
     '500 Users' => 100, 'Enterprise 500 Users' => 100, 'Enterprise 10000+ Users' => 100, 'Unlimited Users' => 100}

  @@commercial_renewal = @@commercial_purchase.reduce({}) { |m, (edition, price)| m[edition] = (price.to_f / 2).ceil; m }

  @@academic_purchase = @@commercial_renewal.update Hash['10 Users' => 10]

  @@academic_renewal = @@academic_purchase.reduce({}) { |m, (edition, price)| m[edition] = (price.to_f / 2).ceil; m }

  def self.all_editions
    @@commercial_purchase
  end

  @@commercial_licenseTypes =  ['Commercial', 'Starter', 'Open Source']

  @@paid_licenseTypes =  @@commercial_licenseTypes << 'Academic'

  def self.paid_licenseTypes
    @@paid_licenseTypes
  end

  def self.price license
    edition = license['edition']
    licenseType = license['licenseType']
    startDate = Date.parse license['startDate']
    endDate = Date.parse license['endDate']
    extra_years = endDate.year - startDate.year - 1
    year_price = case licenseType
    when 'Evaluation', 'Open Source'
      0
    when 'Commercial', 'Starter'
      @@commercial_purchase[edition]
    when 'Academic'
      @@academic_purchase[edition]
    else
      0
    end
    year_price += (year_price.to_f / 2).ceil * extra_years
  end

  def self.find filter
    csv_text = File.read('licenseReport.csv')
    csv = CSV.parse(csv_text, :headers => true)
    filter.each do |key, values|
      case key
      when 'edition', 'technicalContactCountry'
        csv = csv.find_all { |license| values.index(license[key] || 'N/A')}
      when :range
        csv = csv.find_all { |license| values === Date.parse(license['startDate'])}
      end
    end
    csv.map {|license| license['price'] = price license}
    csv
  end
end

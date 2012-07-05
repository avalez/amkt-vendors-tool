require 'csv'

class License 
  @@commercial_purchase =
    {'Evaluation' => 0, '10 Users' => 10, '25 Users' => 10, '50 Users' => 50, '100 Users' => 50,
     '500 Users' => 50, 'Enterprise 10000+ Users' => 100, 'Unlimited Users' => 100}

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
    case licenseType
    when 'Evaluation'
      0
    when 'Commercial', 'Starter', 'Open Source'
      @@commercial_purchase[edition]
    when 'Academic'
      @@academic_purchase[edition]
    end
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

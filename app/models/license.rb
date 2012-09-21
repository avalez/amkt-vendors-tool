require 'csv'

class License < ActiveRecord::Base
  @@commercial_purchase =
    {'Evaluation' => 0, '10 Users' => 10, '25 Users' => 10, '50 Users' => 50,
     '100 Users' => 50, '500 Users' => 100, 'Enterprise 500 Users' => 100,
     'Enterprise 2000 Users' => 100, 'Enterprise 10000 Users' => 100,
     'Enterprise 10000+ Users' => 100, 'Unlimited Users' => 100}

  @@supported_countries = %w{AU US CA AT BE BG CY CZ DK EE FI FR DE GR HU IE IT LV LT LU MT NL PL PT RO SK SI ES SE UK}.
    inject({}) {|h, c| h[c] = true; h}

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

  def self.supported_countries
    @@supported_countries
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

  def self.csv_find filter
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

  def self.import_license row
    license = License.find_by_licenseId row['licenseId']
    if license
      return #[license]
    end
    addOn = AddOn.find_or_create_by_key row['addOnKey'], :name => row['addOnName']
    technicalContact = Contact.find_or_create_by_email row['technicalContactEmail'],
      :name => row['technicalContactName'], :phone => row['technicalContactPhone']
    technicalContactAddress = Address.find_or_create_by_address1_and_postcode_and_country row['technicalContactAddress1'],
      :address2 => row['technicalContactAddress2'], :city => row['technicalContactCity'],
      :state => row['technicalContactState'], :postcode => row['technicalContactPostcode'],
      :country => row['technicalContactCountry']
    billingContact = Contact.find_or_create_by_email row['billingContactEmail'],
      :name => row['billingContactName'], :phone => row['billingContactPhone']
    license = License.find_or_create_by_licenseId row['licenseId'],
      :organisationName => row['organisationName'], :addOn => addOn,
      :technicalContact_id => technicalContact.id,
      :technicalContactAddress_id => technicalContactAddress.id,
      :billingContact_id => billingContact.id,
      :edition => row['edition'], :licenseType => row['licenseType'],
      :startDate => row['startDate'], :endDate => row['endDate'],
      :renewalAction => row['renewalAction']

    [addOn, technicalContact, technicalContactAddress, billingContact, license]
  end

  def self.import csv_licenses
    # TODO http://ruby-doc.org/core-1.9.3/Object.html#method-i-enum_for
    Enumerator.new do |yielder|
      CSV.parse(csv_licenses, :headers => true) do |row|
        license = import_license row
        if license
          yielder.yield license
        end
      end
    end
    #Rails.logger.info licenses
    #licenses.length
  end

  belongs_to :addOn
  belongs_to :technicalContact, :class_name => "Contact"
  belongs_to :technicalContactAddress, :class_name => "Address"
  belongs_to :billingContact, :class_name => "Address"

end

require 'bigdecimal'
require 'bigdecimal/util'

class PercentCoupon

  attr_accessor :name, :percent

  def initialize name, coupon
    @name = name
    @percent = coupon.values[0].to_s.to_d / 100
  end

  def calc price
    [price - price * @percent, 0].max
  end

  def to_str
    percent = (@percent * 100).to_f.round(0).to_s
    @name + " - " + percent + "% off"
  end
end


class AmountCoupon

  attr_accessor :name, :amount

  def initialize name, ant
    @name = name
    @amount = ant.values[0].class == String ? ant.values[0].to_d : ant.values[0]
  end

  def calc price
    [price - @amount, 0].max
  end

  def to_str
    amount = ("%4.2f" % @amount.to_f).to_s
    @name + " - " + amount + " off"
  end
end


class Inventory

  attr_accessor :products, :coupons

  def initialize
    @products = []
    @coupons = []
  end

  def register name, price, promo = {}
    promotion = create_promotion promo
    product = Product.new name, price.to_d, promotion
    if @products.include? product
      raise "Invalid parameters passed."
    end
    if name.size > 40 or price.to_d < 0.01 or price.to_d > 999.99
      raise "Invalid parameters passed."
    end
    @products << product
  end

  def create_promotion hash
    name, value = hash.first
    case name
      when :get_one_free then GetOneFree.new value
      when :package then PackageDiscount.new value
      when :threshold then ThresholdDiscount.new value
      else NoPromotion.new
    end
  end

  def register_coupon name, coupon 
    case coupon.keys[0]
      when :percent then @coupons << PercentCoupon.new(name, coupon)
      when :amount then @coupons << AmountCoupon.new(name, coupon)
    end
  end

  def new_cart
    Cart.new self
  end
 
end


class CartProduct

  attr_accessor :product, :quantity

  def initialize product, quantity
    @product, @quantity = product, quantity
  end
end


class Cart

  attr_accessor :products, :inventory, :coupons, :coupon

  def initialize inventory
    @inventory = inventory
    @products = []
    @coupon
  end

  def has_product name
    @inventory.products.detect{ |p| p.name == name }
  end

  def get_product name
    @inventory.products.detect{ |i| i.name == name }
  end

  def add product, quantity = 1
    if ! has_product product or quantity > 99 or quantity <= 0
      raise "Invalid parameters passed."
    end
    item = @products.detect { |i| i.product.name == product }
    if item then item.quantity += quantity
    else
      item = get_product product
      @products << CartProduct.new(item, quantity) 
    end
  end

  def total
    price = @products.inject(0) { |a, b| a + (b.product.dis_price b.quantity) }
    if @coupon != nil
      price = @coupon.calc price
    end
    price
  end

  def use name
    coupon = @inventory.coupons.detect{ |c| c.name == name }
    if not coupon
      raise "Invalid parameters passed."
    end
    if @coupon != nil
        return 
    end
    @coupon = coupon
  end

  def get_discount 
    @products.inject(0) { |a, b| a + (b.product.dis_price b.quantity) } - total
  end

  def invoice
    p = Printer.new
    s = p.print_start
    tmp = @products.inject(s) { |a, b| a + p.print_item(b.product, b.quantity) }
    tmp + p.print_coupon(@coupon, get_discount) + p.print_total(total)
  end
end


class Product

  attr_accessor :name, :price, :promotion

  def initialize name, price, promotion
    @name = name
    @price = price
    @promotion = promotion
  end

  def get_price quantity
    @price * quantity
  end

  def get_discount quantity, price
    @promotion.get_discount quantity, price
  end

  def dis_price quantity
    (get_price quantity) - (get_discount quantity, @price)
  end
end


class NoPromotion

  def get_discount quantity, price
    return 0
  end
end


class GetOneFree
  
  def initialize promotion
    @number = promotion
  end

  def get_discount quantity, price
    (quantity / @number) * price
  end

  def to_str
     "(buy " + (@number - 1).to_s + ", get 1 free)"    
  end
end


class PackageDiscount

  def initialize promotion
    @number = promotion.first[0]
    @percent = promotion.first[1] / 100.to_s.to_d
  end
  
  def get_discount quantity, price
    (quantity / @number) * price * @percent * @number
  end

  def to_str
    str = "% off for every "
    "(get " + (@percent * 100).to_f.to_i.to_s + str + @number.to_s + ")"
  end
end

class ThresholdDiscount

  def initialize promotion
    @number = promotion.first[0]
    @percent = promotion.first[1] / 100.to_s.to_d
  end

  def get_discount quantity, price
    if quantity <= @number
      0
    else
      (quantity - @number) * price * @percent
    end
  end

  def to_str
    str = "% off of every after the "
    "(" + (@percent * 100).to_f.to_i.to_s + str + sufix(@number) + ")"    
  end

  def sufix number 
    if(number >= 4 and number <= 20) 
      return number.to_s + "th"
    end
    case number % 10
      when 1 then number.to_s + "st"
      when 2 then number.to_s + "nd"
      when 3 then number.to_s + "rd" 
      else number.to_s + "th" 
    end
  end
end


class Printer

  def print_sum price
    if price == 0
      ""
    else
      "|" + ("%4.2f" % (price.to_f).to_s + " |").rjust(11) + "\n"
    end
  end

  def print_start
    print_line + 
    "| Name                                       qty |    price |\n" +
    print_line
  end

  def print_line
    "+------------------------------------------------+----------+\n"
  end

  def print_discount promotion
    if promotion.class != NoPromotion
      ("|   " + promotion.to_str).ljust(49)
    else
      ""
    end
  end

  def print_product product, qty
    tmp = 46 - qty.to_s.size
    "| " + product.name.ljust(tmp) + qty.to_s + " "
  end

  def print_item product, quantity
    a = print_product product, quantity  
    b = print_sum product.get_price quantity
    c = print_discount product.promotion  
    d = print_sum -(product.get_discount quantity, product.price)
    a + b + c + d
  end

  def print_coupon coupon, discount
    if coupon == nil
      ""
    else
      "| Coupon " + coupon.to_str.ljust(40) + print_sum(-discount)
    end
  end

  def print_total sum
    print_line +
    "| TOTAL                                          " + 
    "|" + ("%4.2f" % (sum.to_f).to_s + " |").rjust(11) + "\n" + 
    print_line
  end
end 


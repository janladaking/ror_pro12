module ApplicationHelper
  def money_with_cents_and_with_symbol(amount)
    humanized_money_with_symbol(amount, {no_cents: false, no_cents_if_whole: false})
  end

  def percentage_with_symbol(val)
    "%.1f%" % val
  end

  def plan_price_with_symbol(amount)
    html = humanized_money_with_symbol(Money.new(amount), {no_cents: false, no_cents_if_whole: false, decimal_mark: ',', symbol_position: :after, symbol_after_without_space: true})
    money = amount / 100.0
    if money.round == money
      html.sub!(/(.+)(,00)/, '\1,-')
    end

    html
  end

  def plan_duration_human(months)
    Plan::DURATION_NAME[months] || '-'
  end

  def individual_blog?
    request.subdomain.present? && request.subdomain != "www"
  end
end

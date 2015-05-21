class Admin::OrdersController < Admin::BaseController
  skip_before_action :authenticate_account!, only: :new

  set_tab :orders

  def index
    @orders = current_account.orders.most_recent
  end

  def new
    selected_plan = Plan.by_plan_type(params[:plan])
    if current_account && selected_plan
      current_account.check_upgrade_plan!(selected_plan, params[:duration])
      @order = current_account.orders.build plan_type: params[:plan], plan_duration: params[:duration],
                                            first_name: current_account.profile.first_name,
                                            last_name: current_account.profile.last_name
      @order.calculate_prices
      @order.build_billing_address
    else
      render 'select_plan'
    end

  rescue => ex
    Rails.logger.error ex.inspect
    Rails.logger.error ex.backtrace.join("\n")

    flash.now[:alert] = ex.message
    render 'select_plan'
  end

  def create
    @order = current_account.orders.build(order_params)

    begin
      current_account.check_upgrade_plan!(@order.plan, @order.plan_duration)
    rescue => ex
      redirect_to new_admin_order_path, alert: ex.message
      return
    end

    @order.create_payment!
    redirect_to admin_orders_path, notice: 'Your order is created.'

  rescue => ex
    if @order
      Rails.logger.error @order.errors.to_hash.inspect
      @order.destroy if @order.persisted?
    end

    Rails.logger.error ex.inspect
    Rails.logger.error ex.backtrace.join("\n")

    flash.now[:alert] = 'Sorry, payment is failed. Please try it again'
    render 'new'
  end
  
  private

  def order_params
    params.fetch(:order, {})
          .permit(:first_name, :last_name, :number, :year, :month, :verification_value, :plan_type, :plan_duration,
                  billing_address_attributes: [:id, :address_1, :address_2, :city, :state, :postal_code, :country_code])
          .merge({ip: request.remote_ip})
  end
end

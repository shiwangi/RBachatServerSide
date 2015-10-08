require 'open-uri'
require 'priority_queue'
class PlanFetcherController < ApplicationController
skip_before_filter :verify_authenticity_token
@local_same = 0
@local_diff = 0
@std_same = 0
@std_diff = 0


  def details
  	#json = JSON(params[:messageJson])
  	number = params["mobile_number"]
  	url = "http://trace.bharatiyamobile.com/?numb=#{number}"
  	html = open(url)

  	# Parse the contents of the temporary file as HTML
	doc = Nokogiri::HTML(html)
	circle = ""
	operator = ""
	begin
		circle = doc.css(".numberstyle").css(".bluetext").css("a")[0].text.downcase
		operator = doc.css(".numberstyle").css(".bluetext").css("a")[1].text.downcase
		if (circle.include?"west")
			circle = "westbengal"
		end
	rescue
	end
	render :json => {operator: operator , circle: circle}

  end


  def usage
  	operator = params[:operator]
  	circle = params[:circle]
  	phone_numbers = (params[:numbers]).split(",")

  	duration = (params[:duration])
  	same_op_local_sec = 0
  	same_op_std_sec = 0
  	diff_op_local_sec = 0
  	diff_op_std_sec = 0

  	same_op_local_min = 0
  	same_op_std_min = 0
  	diff_op_local_min = 0
  	diff_op_std_min = 0
  	count = phone_numbers.count

  	for i in 1..(count - 2)
  		number = phone_numbers[i]
  # 		uri = URI.parse("/details?mobile_number=#{number}")
		# response = Net::HTTP.get_response(uri)
		# json = response.body
		# temp_operator = json[:operator]
		# temp_circle = json[:circle]


	  	# Parse the contents of the temporary file as HTML

	  	url = "http://trace.bharatiyamobile.com/?numb=#{number}"
	  	html = open(url)
		doc = Nokogiri::HTML(html)
		sec = duration[i].to_f
		mins = sec / 60.0
		mins = mins.ceil

  	# Parse the contents of the temporary file as HTML
		temp_circle = ""
		temp_operator = ""
		begin
			temp_circle = doc.css(".numberstyle").css(".bluetext").css("a")[0].text.downcase
			temp_operator = doc.css(".numberstyle").css(".bluetext").css("a")[1].text.downcase
			if (temp_circle.include?"west")
				temp_circle = "westbengal"
			end
		rescue
			
		end
		if operator.eql?temp_operator
			if circle.eql?temp_circle
				same_op_local_sec = same_op_local_sec + sec
				same_op_local_min = same_op_local_min + mins

			else
				same_op_std_sec = same_op_std_sec + sec
				same_op_std_min = same_op_std_min + mins
			end

		else
			if circle.eql?temp_circle
				diff_op_local_sec = diff_op_local_sec + sec
				diff_op_local_min = diff_op_local_min + mins

			else
				diff_op_std_sec = diff_op_std_sec + sec
				diff_op_std_min = diff_op_std_min + mins
			end
		end
  	end
  	@local_same = same_op_local_min
  	@std_diff = diff_op_std_min
  	@local_diff = diff_op_local_min
  	@std_same = same_op_std_min
  	calculate_expense_rate_cutter
  	calculate_expense_talk_time

  	rateCutterList = []
  	talkTimeList = []
  	for i in 0..9
  		rateCutterList.push(@rateQueue.delete_min())
  		talkTimeList.push(@talktimeQueue.delete_min())
  	end
  	# render :json => {local_same => [same_op_local_sec , same_op_local_min] , local_diff => [diff_op_local_sec , diff_op_local_min]
			# 	std_same => [same_op_std_sec , same_op_std_min] , std_diff=> [diff_op_std_sec , diff_op_std_min]}
	a={:localSame=> @local_same , :stdDiff=> @std_diff}
	render :json => {:localSameM=> @local_same , :stdDiffM=> @std_diff ,:stdSameM=>@std_same,:localDiffM=>@local_diff, :rateList=>rateCutterList , :talkList=>talkTimeList}

  end

  def current_bill
  	(local_diff+local_same) + 1.5*(std_same+std_diff)
  end

  def max(a , b)
  	if a>b
  		a
  	else
  		b
  	end
  end


  def calculate_expense_rate_cutter
  	@rateQueue = PriorityQueue.new
 #  	@local_same = 10
	# @local_diff = 20
	# @std_same = 30
	# @std_diff = 40
   	
  	RateCutterPlan.all.each do |rc|
  		min = 0
	  	if rc.local === 1
	  		if rc.sameOperator === 1
	  			if(!rc.ratePerMinute.blank?)
	  				min = 1.5*(@std_diff+@std_same) + rc.price + rc.ratePerMinute*(@local_same) + @local_diff
	  			else
	  				diff = max(0,(@local_same)-rc.minutesFree)
	  				min = 1.5*(@std_diff+@std_same) + rc.price + diff + @local_diff
	  			end

	  		else	  			
	  			if(!rc.ratePerMinute.blank?)
	  				min = 1.5*(@std_diff+@std_same) + rc.price + rc.ratePerMinute*(@local_same + @local_diff)
	  			else
	  				diff = max(0,(@local_same + @local_diff) - rc.minutesFree)
	  				min = 1.5*(@std_diff+@std_same) + rc.price + diff
	  			end
	  		end
	  	else 
	  		if rc.sameOperator === 1
	  			if(!rc.ratePerMinute.blank?)
	  				min = rc.ratePerMinute*(@std_same+@local_same) + 1.5*@std_diff+ rc.price + @local_diff
	  			else
	  				diff = max(0,(@std_same+@local_same) - rc.minutesFree)
	  				min = diff*1.5 + 1.5*@std_diff+ rc.price + @local_diff
	  			end
	  		else
	  			if(!rc.ratePerMinute.blank?)
	  				min = rc.ratePerMinute*(@std_diff+@std_same + (@local_same + @local_diff) ) + rc.price 
	  			else
	  				diff = max(0, @std_diff+@std_same + (@local_same + @local_diff) - rc.minutesFree)
	  				min = diff*1.5 + rc.price 
	  			end
	  		end
	  	end
	  	@rateQueue[rc]=min
	end
  end



  def calculate_expense_talk_time
  	@talktimeQueue = PriorityQueue.new
   	
  	TalkTimePlan.all.each do |rc|
  		if(!rc.price.blank? && !rc.balance.blank?)
	  		min = 0	  	
		  	min = rc.price-rc.balance
		  	@talktimeQueue[rc]=min
		end
	end
  end


  def fetchRatecutters
		# Parse the URI and retrieve it to a temporary file
		operators = ["vodafone" , "airtel" , "idea" , "reliance"]
		states = ["karnataka" , "westbengal"]
		operators.each do |operator|
			states.each do |state|

				# url = 'https://www.komparify.com/regions/' + 'params[:state]' + '/carriers/' + params[:operator] + '/topuptype/voice+call'
				url = 'https://www.komparify.com/regions/' + state + '/carriers/' + operator + '/topuptype/voice+call'
				news_tmp_file = open(url,:proxy => "http://10.3.100.207:8080")

				# Parse the contents of the temporary file as HTML
				doc = Nokogiri::HTML(news_tmp_file)

				# Define the css selectors to be used for extractions, most
				article_css_class         =".planrow"
				article_header_css_class  ="td"
				article_summary_css_class ="span.nounderlinedescriptionlink"

				# extract all the articles 
				articles = doc.css(article_css_class)

				#html output
				@html = "["

				#extract the title from the articles
				articles.each do |article|
					title_nodes = article.css(article_header_css_class)


				  # since there are multiple titles for each entry on google news
				  # for this demo we only want the first (topmost)
				  #
				  # its very easy to do, since title_nodes is of type NodeSet which implements Enumerable (http://ruby-doc.org/core-2.0.0/Enumerable.html)
				  # > title_nodes.class
				  #  => Nokogiri::XML::NodeSet 
				  # > title_nodes.class.ancestors
				  #   => [Nokogiri::XML::NodeSet, Enumerable, Object, Kernel, BasicObject]
					name  = title_nodes[0]
					rate = title_nodes[1]
					validity = title_nodes[2]


				  # Even when the css selector returns only one element, its type is also Nokogiri::XML::NodeSet
					summary_node = article.css(article_summary_css_class) 
				  # > summary_node.class
				  #  => Nokogiri::XML::NodeSet 
				  # > summary_node.size
				  #  => 1 

		      # Create an "---------" line for the title
		  
				  # Extracting the text from an Nokogiri::XML::Element is easy by calling the #text method, 
				  # notice how we can also do it on the NodeSet, 
				  # there it as a different semantic by invoking #text in all the children nodes
					sameOperator = 1
					if summary_node.text.include?("as well as other network")
						sameOperator = 0
					end

					local = 1;
					if summary_node.text.include?("STD")
						local = 0
					end
					temp=[]
					ratePerMinute = ""
					freeMinutes = ""
					if summary_node.text.include?("@")
						temp = summary_node.text.split(" ")
						l = temp.length - 3
						ratePerMinute = temp[l]
					else
						temp = summary_node.text.split(" ")
						l = temp.length - 2
						freeMinutes = temp[l]
					end


					RateCutterPlan.create(:name => name.text , :validity => validity.text , :description => summary_node.text , :price => rate.text.split(" ")[1] ,:state => state , :operator => operator , :local => local , :sameOperator => sameOperator,:ratePerMinute => ratePerMinute , :minutesFree => freeMinutes)
			  	 end
			end
		end
	end

	def fetchTalkTime
		# Parse the URI and retrieve it to a temporary file
		operators = ["vodafone" , "airtel" , "idea" , "reliance"]
		states = ["karnataka" , "westbengal"]
		operators.each do |operator|
			states.each do |state|

				# url = 'https://www.komparify.com/regions/' + 'params[:state]' + '/carriers/' + params[:operator] + '/topuptype/voice+call'
				url = 'https://www.komparify.com/regions/' + state + '/carriers/' + operator + '/topuptype/recharge+voucher'
				news_tmp_file = open(url,:proxy => "http://10.3.100.207:8080")

				# Parse the contents of the temporary file as HTML
				doc = Nokogiri::HTML(news_tmp_file)

				# Define the css selectors to be used for extractions, most
				article_css_class         =".planrow"
				article_header_css_class  ="td"
				article_summary_css_class ="span.nounderlinedescriptionlink"

				# extract all the articles 
				articles = doc.css(article_css_class)

				#html output
				@html = "["

				#extract the title from the articles
				articles.each do |article|
					title_nodes = article.css(article_header_css_class)


				  # since there are multiple titles for each entry on google news
				  # for this demo we only want the first (topmost)
				  #
				  # its very easy to do, since title_nodes is of type NodeSet which implements Enumerable (http://ruby-doc.org/core-2.0.0/Enumerable.html)
				  # > title_nodes.class
				  #  => Nokogiri::XML::NodeSet 
				  # > title_nodes.class.ancestors
				  #   => [Nokogiri::XML::NodeSet, Enumerable, Object, Kernel, BasicObject]
					name  = title_nodes[0]
					rate = title_nodes[1]
					validity = title_nodes[2]
				#  debugger
				  

					  # Even when the css selector returns only one element, its type is also Nokogiri::XML::NodeSet
					summary_node = article.css(article_summary_css_class) 
					  # > summary_node.class
					  #  => Nokogiri::XML::NodeSet 
					  # > summary_node.size
					  #  => 1 
				 	if !summary_node.blank?
			      # Create an "---------" line for the title
			  
					  # Extracting the text from an Nokogiri::XML::Element is easy by calling the #text method, 
					  # notice how we can also do it on the NodeSet, 
					  # there it as a different semantic by invoking #text in all the children nodes
				
						temp = summary_node.text.split(" ")
						l = temp.length - 1 
						if !temp[l].blank?
							len = temp[l].length
							balance = temp[l].slice(3,len-4)
							
							TalkTimePlan.create(:name => name.text , :validity => validity.text , :description => summary_node.text , :price => rate.text.split(" ")[1] ,:state => state , :operator => operator , :balance => balance)
					  	end
				  	end
		  	 	end
			end
		end
	end
end

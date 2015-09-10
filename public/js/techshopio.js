/*
	Jquery JS resources for TechShopIO.
*/

$(document).ready( function() {

	//
	// In Page Search engine on List view
	//
	// Reset button
	$("#reset-filter").click(function(){
	  $("#q").val("");
	  $("table#techShopList .rch").show();
	  $("#filter-count").text("").hide();
	  $(this).hide();
	});

	// Search on keyup
	$("#q").keyup(function(){
	    var filter = $(this).val();
	    var count = 0;
	    $("#reset-filter").show();
	    // Loop through the lines list
	    $("table#techShopList .rch").each(function(){
	         // Recherche
	        if ($(this).text().search(new RegExp(filter, "ig")) < 0) {
	          $(this).fadeOut();
	        } else {
	            $(this).show();
	            count++;
	        }
	    });
	    s = count > 1 ? "s" : "";
	    $("#filter-count").text(count + " items").show(); //" <%= _t 'result' %>" 
	 });

	//
    // View picture in modal popup
    //
	$(".modalPicture").click(function(){
		var src = $(this).attr("src").replace(/thumb-/g, '');
		$("#myModalLabel").html($(this).attr("alt"));
		$("#bigPicture").attr("src", src);
	});

	//
	// Bind submit button for new/modify view
	//
	$('#btnSubmit').click(function(){
		$('#newModifyFrm').submit();
	});
});

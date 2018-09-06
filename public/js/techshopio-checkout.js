/*
*  JS Resources for Checkout feature. out.erb Template
*/

$(document).ready( function() {
	var inDtGrp = $("#chkin_date_Grp");
	var inDtErrMsg = $("#chkin_date_TT");
	var code = $( "#itemCode" ).val();
	var cancekBtn = $( "#cancelBtn" );
	var chkBtn = $( "#checkoutBtn" );
	var frm = $("#checkoutForm");
	var cnt = $('#tags-list-panel, #tags-list');
	var countTags = $( "#tags-list" ).children(); // TODO : Compter le nombre d'éléments existants
	// Initial state of the page
	chkBtn.prop("disabled", true);
	$(".alert").hide();

	cnt.each(function( index ) {
	  var action = "add";
	  // for every click on or in this element
	  cnt.eq(index).on('click', '> *', function() {
	    // append will remove the element
	    // Number( !0 ) => 1, Number( !1 ) => 0
	    if ( Number(!index) == 0) {
	    	// Adding tags
	    	countTags++;
	    } else {
	    	// Removing Tags
	    	countTags--;
	    	action = "remove";
	    }  
	    // Sending ajax request
		$.ajax({
		  url: APP_PATH + "/tags/" + action + "/?code=" + code + "&id=" + this.id.replace('tag', '')
		})
		  .done(function( res ) {
		    console.log( res );
		  });
	    // updating the right layer
	    cnt.eq( Number(!index) ).append( this );
	    // Set right button state
	    chkBtn.prop("disabled", (countTags <= 0) );
	  });
	});

	// Controling check in & out date interval
	// Check in date value must be later than chek out date
	function checkDates() {
		var din = parseInt($('#chkin_date').val().replace(/-/g, '')),
			dout = parseInt($('#chkout_date').val().replace(/-/g, ''));
		if (isNaN(din)) {
			din = 0;
		}
		 return (din >= dout);
	}

	// Checkout button Listener
	chkBtn.click(function() {
		var chkdt = (USE_CHECKINOUT_DATE == "Y") ? checkDates() : true;
		$(".alert").hide();
		inDtGrp.removeClass("has-error");
		if (chkdt) {
			frm.submit();
		} else {
			inDtGrp.addClass("has-error");
			inDtErrMsg.show();
		}
	});

	// Annulation Button
	cancekBtn.click(function(){
		location.href=APP_PATH + "/item/checkin?code="+code;
	});

});
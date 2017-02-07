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
	    $("#filter-count").text(count + " items").show();
	 });

	//
	// Bind submit button from list actions -> In / Out / New item
	//
	$('#btnGo').click(function(){
		$('#frmGo').submit();
	});

	//
	// Bind submit button for new/modify view
	//
	$('#btnSubmit').click(function(){
		$('#newModifyFrm').submit();
	});

	//
	// Auto upload picture
	//
	$(document).on('change', '.btn-file :file', function(e) {
		e.preventDefault();

		// from an input element
	    var filesToUpload = this.files;
	    var file = filesToUpload[0];

	    var	code = $(this).attr("id").replace(/^picture-/g, '');
		var ext = $(this).val().substr( $(this).val().lastIndexOf('.') );
	    var	label = code + ext;
	    var	labelthumb = "thumb-" + code + ".png";

		var reader = new FileReader();  

		reader.onload = function(e) 
		{
			var image = new Image();
			image.src = e.target.result;

			image.onload = function() {
		        // access image size here 
		        console.log(this.width);
	        	// Resizing
	        	var canvas = document.createElement("canvas");
	        	var ctx = canvas.getContext("2d");
	        	ctx.drawImage(image, 0, 0);
	        	
		        var maxW = 100;
		        var maxH = 100;
		        var width = image.width;
		        var height = image.height;

		        if (width > height) {
		          if (width > maxW) {
		            height *= maxW / width;
		            width = maxW;
		          }
		        } else {
		          if (height > maxH) {
		            width *= maxH / height;
		            height = maxH;
		          }
		        }
		        canvas.width = width;
		        canvas.height = height;
		        var ctx = canvas.getContext("2d");
		        ctx.drawImage(image, 0, 0, width, height);

		        var dataurl = canvas.toDataURL("image/png");
		        $('#img-'+code).attr("src", dataurl);     

		        // Uploading picture
				var data = new FormData();
				data.append('code', code);
				data.append('label', label);
				data.append('labelthumb', labelthumb);
				data.append('thumb', dataurl);
				data.append('picture', file);

				// Posting data for thumbnail
				$.ajax({
				    url: APP_PATH + '/item/picture', 
				    type: 'POST',
				    data: data,
				    cache: false,
					contentType: false, 
				    processData: false,
				    success : function(response){
				    	// Refresh the thumbnail on list
				    	ajax_get_thumbnail( '#img-' + code, labelthumb );
				     },
				    error : function(response){
				    	console.log(response);
				     }
				});
			};
		}
		// Load files into file reader
	    reader.readAsDataURL(file);
	});

	//
    // View picture in modal popup
    //
	$( ".modalPicture" ).click(function(){
		// var src = $(this).attr("src").replace(/thumb-/g, '');
		var itemId = $(this).attr("id").replace(/img-/g, '');
		$.ajax({
		    url: APP_PATH + '/item/picture/path?code='+itemId, 
		    type: 'GET',
		    success : function(response){
		    	// Refresh the thumbnail on list
		    	ajax_get_thumbnail( 'bigPicture', response );
		     },
		    error : function(response){
		    	console.log(response);
		     }
		});
	});

	//
    // Massive checkout popup
    //
	$( "#massiveOutput" ).click(function(){
		$(this).addClass("active");
		$("#singleOutput").removeClass("active");
	});

	$("#singleOutput").click(function(){
		$(this).addClass("active");	
		$("#massiveOutput").removeClass("active");
	});

	//
	// Reload thumbnail in ajax mode.
	//
	function ajax_get_thumbnail(id, name) {
		var d = new Date();
		$("#" + id).attr("src", APP_PATH + '/pictures/' + name + "?" + d.getTime());
	}
});

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

		var img = document.createElement("img");
		var reader = new FileReader();  

		reader.onload = function(e) 
		{
	        img.src = e.target.result;

	        var canvas = document.createElement("canvas");
	        var ctx = canvas.getContext("2d");
	        ctx.drawImage(img, 0, 0);

	        var maxW = 100;
	        var maxH = 100;
	        var width = img.width;
	        var height = img.height;

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
	        ctx.drawImage(img, 0, 0, width, height);

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
				contentType: false, //'multipart/form-data; charset=utf-8',
			    processData: false,
			    success : function(response){
			    	// Refresh the thumbnail on list
			    	d = new Date();
			    	$('#img-'+code).attr("src", APP_PATH + '/pictures/thumb-' + label + "?" + d.getTime());
			     },
			    error : function(response){
			    	console.log(response);
			     }
			});

	    }
	    // Load files into file reader
	    reader.readAsDataURL(file);
	});

});

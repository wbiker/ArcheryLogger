var scores = [20, 18, 16, 14, 12, 10, 8, 6, 4];

$(document).ready(function() {
	createTargets(1);
});

function parcourChanged(value) {
    console.log("given value:", value);
	// unfortunately, it is hard coded yet.
	// in the database table 
	// 1 = 20
	// 2 = 28
	// 3 = 30
    if(1 == value) {
		createTargets(1);
    } else if(2 == value) {
		createTargets(2);
    }
	else if(3 == value) {
		// 30 targets to show
		createTargets(3);

	}
}

function createTargets(parcourid) {	
	$.getJSON("get_targets", { "parcourid" : parcourid} )
		.done(function(json) {
			console.log("Got json from server");
			console.log(JSON.stringify(json));
			var targetblock = document.getElementById('targetarea');
			//console.log(JSON.stringify(targetblock));
			if(null != targetblock) {
				targetblock.parentNode.removeChild(targetblock);
			}
			jQuery('<tr></tr>', {
				id: "targetarea"
			}).appendTo("#tbody");

			targetblock = $('#targetarea');
			var tr = jQuery('<tr></tr>').appendTo(targetblock);
			for(var i=1; i<=json.count; i++) {
				if(i == 11 || i == 21) {
					tr = jQuery('<tr></tr>').appendTo(targetblock);
				}
				var td = jQuery('<td></td>').appendTo(tr);
				jQuery("<label>Target_" + i + "</label>").appendTo(td);
				jQuery('<br>').appendTo(td);
				jQuery('<input type="checkbox" name="targetid" value="20" id="targetid">20<br>').appendTo(td);
			}
		})
		.fail(function(jqxhr, textStatus, error) {
			var err = textStatus + ", " + error;
			console.log("Request failed: " + err);
		});
}

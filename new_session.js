var scores = [20, 18, 16, 14, 12, 10, 8, 6, 4];

function parcourChanged(value) {
    console.log("given value:", value);
    if(1 == value) {
        // remove lastblock
        var lastblock = document.getElementById('lastblock');
        console.log("lastblock: ", lastblock);
        if(null == lastblock) {
            alert("lastblock not found!");
            return;
        }
        lastblock.parentNode.removeChild(lastblock);
    }
    else {
        console.log("create lastblock");
        
        var tr = document.createElement('tr');
        tr.setAttribute('id', 'lastblock');
        // create 8 targets
        for(var i=21; i< 29; i++) {
            var td = document.createElement('td');
            td.appendChild(document.createTextNode("Target_" + i));
            td.appendChild(document.createElement('br'));

            for(var x=0; x<9; x++) {
                var input = document.createElement('input');
                input.type = 'checkbox';
                input.value = scores[x]; // score array has got the scores 20, 18. 16, 14, 12, 10, 8, 6 and 4
                input.name = i;

                console.log(input);
                td.appendChild(input);
                td.appendChild(document.createTextNode(scores[x]));
                td.appendChild(document.createElement('br'));
            }
            tr.appendChild(td);
        }

        var submitRow = document.getElementById('submit');
        var tbody = document.getElementById('tbody');
        tbody.insertBefore(tr, submitRow);
    }   
}

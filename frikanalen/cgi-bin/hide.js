function show_cat() {
    document.getElementById("choose_cat").style.display = "none";
	document.getElementById("list_cat").style.display = "block";
	document.getElementById("choose_ed").style.display = "block";
	document.getElementById("list_ed").style.display = "none";
	document.getElementById("choose_org").style.display = "block";
	document.getElementById("list_org").style.display = "none";
}

function show_ed() {
    document.getElementById("choose_cat").style.display = "block";
	document.getElementById("list_cat").style.display = "none";
	document.getElementById("choose_ed").style.display = "none";
	document.getElementById("list_ed").style.display = "block";
	document.getElementById("choose_org").style.display = "block";
	document.getElementById("list_org").style.display = "none";
}

function show_org() {
    document.getElementById("choose_cat").style.display = "block";
	document.getElementById("list_cat").style.display = "none";
	document.getElementById("choose_ed").style.display = "block";
	document.getElementById("list_ed").style.display = "none";
	document.getElementById("choose_org").style.display = "none";
	document.getElementById("list_org").style.display = "block";
}
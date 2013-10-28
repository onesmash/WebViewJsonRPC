;(function() {
	if(window.jsonRPC) {
		return;
	}

	var CustomProtocolScheme = 'jsrpc';

	var iframe =  document.createElement('iframe');
	iframe.style.display = 'none';
	document.documentElement.appendChild(iframe);

	var _current_id = 0;

	var _callbacks = {};

	var jsonRPC = {};

	function doCall(method, params, success_cb, error_cb) {
        if ('id' in request && typeof success_cb !== 'undefined') { 
            _callbacks[request.id] = { success_cb: success_cb, error_cb: error_cb }; 
        } 
        iframe.src = CustomProtocolScheme + '://' + JSON.stringify(request);
	}

	jsonRPC.call = function(method, params, success_cb, error_cb) {
		var request = { 
				jsonrpc : '2.0', 
                method  : method, 
                params  : params, 
                id      : _current_id++  
            }; 
        doCall(request, success_cb, error_cb);
	}

	jsonRPC.notify = function(method, params) {
		var request = { 
				jsonrpc : '2.0', 
                method  : method, 
                params  : params, 
            }; 
        doCall(request, success_cb, error_cb);
    };

    jsonRPC.onMessage = function(message) {
    	try {
            
            var response = message;
        
            if(typeof response === 'object'
                && 'jsonrpc' in response
                && response.jsonrpc === '2.0') {
                if('result' in response && _callbacks[response.id]) {
                    var success_cb = _callbacks[response.id].success_cb;
                    delete _callbacks[response.id];
                    success_cb(response.result);
                    return;
                } else if('error' in response && _callbacks[response.id]) {
                    
                    var error_cb = _callbacks[response.id].error_cb;
                    delete _callbacks[response.id];
                    error_cb(response.error);
                    return;
                }
            }
        }
        catch (err) {
           
        }
    }

    window.jsonRPC = jsonRPC;

})();
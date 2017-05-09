// Numenta Platform for Intelligent Computing (NuPIC)
// Copyright (C) 2015, Numenta, Inc.  Unless you have purchased from
// Numenta, Inc. a separate commercial license for this software code, the
// following terms and conditions apply:
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero Public License version 3 as
// published by the Free Software Foundation.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
// See the GNU Affero Public License for more details.
//
// You should have received a copy of the GNU Affero Public License
// along with this program.  If not, see http://www.gnu.org/licenses.
//
// http://numenta.org/licenses/


/**
* Factory used to create {@link TaurusClient} instances.
*/
open class TaurusClientFactory : GrokClientFactory {
    
    // Reuse client object
    var client: TaurusClient!
    
    var provider : AWSCredentialsProvider
    var region : AWSRegionType
    
    /** initialize client factory
        - parameter provider: AWS creditionals to use
        - parameter region: region hosting
    */
    init (provider : AWSCredentialsProvider, region: AWSRegionType ){
        self.provider = provider
        self.region = region
    }
    
    /** create clients
        - parameter serverUrl : ignored
        - parameter password : ignored
        - returns: Clienty
    */
    open func createClient( _ serverUrl: String!, pass: String!)  ->GrokClient! {
        if (client == nil) {
            client = TaurusClient(provider: provider, region : region)
        }
        return client as GrokClient;
    }

}

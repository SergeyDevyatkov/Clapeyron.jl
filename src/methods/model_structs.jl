abstract type EoS end
abstract type SAFT <: EoS end

abstract type PCSAFTFamily <: SAFT end
abstract type ogSAFTFamily <: SAFT end
abstract type SAFTVRMieFamily <: SAFT end

struct SAFTVRMie <: SAFTVRMieFamily; components; parameters::SAFTVRMieParams end
struct PCSAFT <: PCSAFTFamily; components; sites; parameters::PCSAFTParams end
struct sPCSAFT <: PCSAFTFamily; components; sites; parameters::sPCSAFTParams end
struct ogSAFT <: ogSAFTFamily; components; parameters::ogSAFTParams end
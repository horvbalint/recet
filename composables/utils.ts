export const { isMobile } = useAppBreakpoints()
export const pageHeaderType = computed(() => isMobile.value ? 'section' : 'page')
